#
# = Ruby Zonefile - Parse and manipulate DNS Zone Files.
#
# == Description
# This class can read, manipulate and create DNS zone files. It supports A, AAAA, MX, NS, SOA, 
# TXT, CNAME, PTR and SRV records. The data can be accessed by the instance method of the same
# name. All except SOA return an array of hashes containing the named data. SOA directly returns the 
# hash since there can only be one SOA information.
#
# The following hash keys are returned per record type:
#
# * SOA
#    - :ttl, :primary, :email, :serial, :refresh, :retry, :expire, :minimumTTL
# * A
#    - :name, :ttl, :class, :host
# * MX
#    - :name, :ttl, :class, :pri, :host
# * NS
#    - :name, :ttl, :class, :host
# * CNAME
#    - :name, :ttl, :class, :host
# * TXT
#    - :name, :ttl, :class, :text
# * A4 (AAAA)
#    - :name, :ttl, :class, :host
# * PTR
#    - :name, :ttl, :class, :host
# * SRV
#    - :name, :ttl, :class, :pri, :weight, :port, :host
#
# == Examples
#
# === Read a Zonefile
#
#  zf = Zonefile.from_file('/path/to/zonefile.db')
#  
#  # Display MX-Records
#  zf.mx.each do |mx_record|
#     puts "Mail Exchagne with priority: #{mx_record[:pri]} --> #{mx_record[:host]}"
#  end
#
#  # Show SOA TTL
#  puts "Record Time To Live: #{zf.soa[:ttl]}"
#
#  # Show A-Records
#  zf.a.each do |a_record|
#     puts "#{a_record[:name]} --> #{a_record[:host]}"
#  end
#
#
# ==== Manipulate a Zonefile
#
#  zf = Zonefile.from_file('/path/to/zonefile.db')
#
#  # Change TTL and add an A-Record
#
#  zf.soa[:ttl] = '123123'      # Change the SOA ttl
#  zf.a << { :class => 'IN', :name => 'www', :host => '192.168.100.1', :ttl => 3600 }  # add A-Record
#
#  # Setting PTR records (deleting existing ones)
#
#  zf.ptr = [ { :class => 'IN', :name=>'1.100.168.192.in-addr.arpa', :host => 'my.host.com' },
#             { :class => 'IN', :name=>'2.100.168.192.in-addr.arpa', :host => 'me.host.com' } ]
#
#  # Increase Serial Number
#  zf.new_serial
#
#  # Print new zonefile
#  puts "New Zonefile: \n#{zf.output}"
#
# == Author
# 
# Martin Boese, based on Simon Flack Perl library DNS::ZoneParse
#


# GloboDns record types:
#
#   [ 0] "A",
#   [ 1] "AAAA",
#   [ 2] "CERT",
#   [ 3] "CNAME",
#   [ 4] "DLV",
#   [ 5] "DNSKEY",
#   [ 6] "DS",
#   [ 7] "IPSECKEY",
#   [ 8] "KEY",
#   [ 9] "KX",
#   [10] "LOC",
#   [11] "MX",
#   [12] "ns",
#   [13] "NSEC",
#   [14] "NSEC3",
#   [15] "NSEC3PARAM",
#   [16] "PTR",
#   [17] "RRSIG",
#   [18] "SIG",
#   [19] "SOA",
#   [20] "SPF",
#   [21] "SRV",
#   [22] "TA",
#   [23] "TKEY",
#   [24] "TSIG",
#   [25] "TXT"

require 'pathname'

class Zonefile
    RECORDS = %w{ mx a aaaa ns cname txt ptr srv soa }
    attr :records
    attr :all_records
    attr :soa
    attr :data
    # global $ORIGIN option
    attr :origin 
    # global $TTL option
    attr :ttl

    def method_missing(m, *args)
        mname = m.to_s.sub("=","")
        return super unless RECORDS.include?(mname)

        if m.to_s[-1].chr == '=' then
            @records[mname.intern] = args.first
            @records[mname.intern]
        else 
            @records[m]
        end
    end

    # Compact a zonefile content - removes empty lines, comments, 
    # converts tabs into spaces etc...
    def self.simplify(zf)
        # zf.gsub(/("(""|[^"])*")|;.*$/, '\1').gsub(/[\r\n]+/, "\n").gsub(/(\(.*?\))/m){ $1.gsub(/\s+/, ' ') }.gsub(/\s*[\n\r]\s*/, "\n").strip
        zf.gsub(/("(""|[^"])*")|;.*$/, '\1').gsub(/[\r\n]+/, "\n").gsub(/(\(.*?\))/m){ $1.gsub(/\s+/, ' ') }.strip

        # # concatenate everything split over multiple lines in parentheses - remove ;-comments in block
        # zf = zf.gsub(/(\([^\)]*?\))/) { |m| m.split(/\n/).map { |l| l.gsub(/\;.*$/, '') }.join("\n").gsub(/[\r\n]/, '') }

        # zf.split(/\n/).map do |line|
        #     r = line.gsub(/\t/, ' ')
        #     r = r.gsub(/\s+/, ' ')
        #     # FIXME: this is ugly and not accurate, couldn't find proper regex:
        #     #   Don't strip ';' if it's quoted. Happens a lot in TXT records.
        #     (0..(r.length - 1)).find_all { |i| r[i].chr == ';' }.each do |comment_idx|
        #         if !r[(comment_idx+1)..-1].index(/['"]/) then
        #             r = r[0..(comment_idx-1)]
        #             break
        #         end
        #     end
        #     r
        # end.delete_if { |line| line.empty? || line[0].chr == ';'}.join("\n")
    end

    # create a new zonefile object by passing the content of the zonefile
    def initialize(zonefile = '', file_name = nil, origin = nil, chroot_dir = nil, options_dir = nil)
        @data        = zonefile
        @filename    = file_name
        @origin      = origin || (file_name ? file_name.split('/').last : '')
        @chroot_dir  = chroot_dir
        @options_dir = options_dir

        @all_records = []
        @records     = {}
        @soa         = {}
        RECORDS.each { |r| @records[r.intern] = [] }
        parse
    end

    # True if no records (except sao) is defined in this file
    def empty?
        RECORDS.each do |r|
            return false unless @records[r.intern].empty?
        end
        true
    end

    # Create a new object by reading the content of a file
    def self.from_file(file_name, origin = nil, chroot_dir = nil, options_dir = nil)
        Zonefile.new(File.read(file_name), file_name.split('/').last, origin, chroot_dir, options_dir)
    end

    def add_record(type, data = {})
        type_sym            = type.downcase.to_sym
        type_str            = type.upcase
        data[:name]         = @all_records.last[:name] if (data[:name].nil? || data[:name].strip == '') && @all_records.last
        @records[type_sym] << data if @records.has_key?(type_sym)
        @all_records       << data.merge({:type => type_str})
    end

    # Generates a new serial number in the format of YYYYMMDDII if possible
    def new_serial
        base = "%04d%02d%02d" % [Time.now.year, Time.now.month, Time.now.day ]

        if ((@soa[:serial].to_i / 100) > base.to_i) then
            ns = @soa[:serial].to_i + 1
            @soa[:serial] = ns.to_s
            return ns.to_s
        end

        ii = 0
        while (("#{base}%02d" % ii).to_i <= @soa[:serial].to_i) do
            ii += 1
        end
        @soa[:serial] = "#{base}%02d" % ii   
    end

    def parse_line(line)
        valid_name = /[\@a-z_\-\.0-9\*]+/i
        valid_ip6  = /[\@a-z_\-\.0-9\*:]+/i
        rr_class   = /\b(?:IN|HS|CH)\b/i
        rr_type    = /\b(?:NS|A|CNAME)\b/i
        rr_ttl     = /(?:\d+[wdhms]?)+/i
        ttl_cls    = /(?:(#{rr_ttl})\s+)?(?:(#{rr_class})\s+)?/

        if line =~ /^\$ORIGIN\s*(#{valid_name})/ix
            @origin = $1

        elsif line =~ /\$TTL\s+(#{rr_ttl})/i 
            @ttl = $1

        elsif line =~ /\$INCLUDE\s+("[\w\. \/_\-]+"|[\w\.\/_\-]+)\s+("[\.\w_]+"|[\.\w_]+)?/i 
            old_origin = @origin
            filename   = $1
            @origin    = $2 if $2
            final_path = Pathname.new(filename).absolute? ? File.join(@chroot_dir || '', filename) : File.join(@chroot_dir || '', @options_dir || '', filename)
            File.exists?(final_path) or raise RuntimeError.new("[Zonefile][ERROR] unable to find included file \"#{final_path}\"")
            content    = File::read(final_path)
            Zonefile.simplify(content).each_line do |line|
                parse_line(line)      
            end
            @origin = old_origin

        elsif line =~ /^(#{valid_name})? \s*
            #{ttl_cls}
            (#{rr_type}) \s+
            (#{valid_name})
            /ix
            add_record($4, :name => $1, :ttl => $2, :class => $3, :host => $5)

        elsif line=~/^(#{valid_name})? \s*
            #{ttl_cls}
            AAAA \s+
            (#{valid_ip6})               
            /x
            add_record('aaaa', :name => $1, :ttl => $2, :class => $3, :host => $4)

        elsif line=~/^(#{valid_name})? \s*
            #{ttl_cls}
            MX \s+
            (\d+) \s+
            (#{valid_name})
            /ix
            add_record('mx', :name => $1, :ttl => $2, :class => $3, :pri => $4.to_i, :host => $5)

        # elsif line=~/^(#{valid_name})? \s*
        #     #{ttl_cls}
        #     SRV \s+
        #     (\d+) \s+
        #     (\d+) \s+
        #     (\d+) \s+
        #     (#{valid_name})
        #     /ix
        #     add_record('srv', :name => $1, :ttl => $2, :class => $3, :pri => $4, :weight => $5, :port => $6, :host => $7)

        elsif line =~ /^(#{valid_name}) \s+
            #{ttl_cls}
            SOA \s+
            (#{valid_name}) \s+
            (#{valid_name}) \s*
            \(?\s*
              (#{rr_ttl}) \s+
              (#{rr_ttl}) \s+
              (#{rr_ttl}) \s+
              (#{rr_ttl}) \s+
              (#{rr_ttl}) \s*
              \)?
              /ix
            ttl = @soa[:ttl] || $2 || ''
            @soa[:type]       = 'SOA'
            @soa[:name]       = $1
            @soa[:origin]     = $1
            @soa[:ttl]        = ttl
            @soa[:primary]    = $4
            @soa[:email]      = $5
            @soa[:serial]     = $6
            @soa[:refresh]    = $7
            @soa[:retry]      = $8
            @soa[:expire]     = $9
            @soa[:minimumTTL] = $10
            @all_records     << @soa

        elsif line=~ /^(#{valid_name})? \s*
            #{ttl_cls}
            PTR \s+
            (#{valid_name})
            /ix
            add_record('ptr', :name => $1, :class => $3, :ttl => $2, :host => $4)

        elsif line =~ /^(#{valid_name})? \s* #{ttl_cls} ([A-Z0-9]+) \s+ (.*)$/ix
            # add_record('txt', :name => $1, :ttl => $2, :class => $3, :text => $4.strip)
            add_record($4, :name => $1, :ttl => $2, :class => $3, :host => $5)

        else
            STDERR.puts "[WARNING][Zonefile.parse] unparseable line: \"#{line}\""

        end
    end

    def parse
        Zonefile.simplify(@data).each_line do |line|
            parse_line(line)      
        end
    end


    # Build a new nicely formatted Zonefile
    def output
        out =<<-ENDH
;
;  Database file #{@filename || 'unknown'} for #{@origin || 'unknown'} zone.
;       Zone version: #{self.soa[:serial]}
;
#{self.soa[:origin]}            #{self.soa[:ttl]} IN  SOA  #{self.soa[:primary]} #{self.soa[:email]} (
#{self.soa[:serial]}    ; serial number
#{self.soa[:refresh]}   ; refresh
#{self.soa[:retry]}     ; retry
#{self.soa[:expire]}    ; expire
#{self.soa[:minimumTTL]}        ; minimum TTL
                                )

#{@origin ? "$ORIGIN #{@origin}" : ''}
#{@ttl ? "$TTL #{@ttl}" : ''}

; Zone NS Records
ENDH
self.ns.each do |ns|
    out <<  "#{ns[:name]}      #{ns[:ttl]}     #{ns[:class]}   NS      #{ns[:host]}\n"
end
out << "\n; Zone MX Records\n" unless self.mx.empty?
self.mx.each do |mx|
    out << "#{mx[:name]}       #{mx[:ttl]}     #{mx[:class]}   MX      #{mx[:pri]} #{mx[:host]}\n"
end

out << "\n; Zone A Records\n" unless self.a.empty?
self.a.each do |a|
    out <<  "#{a[:name]}    #{a[:ttl]}      #{a[:class]}    A       #{a[:host]}\n"
end   

out << "\n; Zone CNAME Records\n" unless self.cname.empty?
self.cname.each do |cn|
    out << "#{cn[:name]}       #{cn[:ttl]}     #{cn[:class]}   CNAME   #{cn[:host]}\n"
end  

out << "\n; Zone AAAA Records\n" unless self.aaaa.empty?
self.aaaa.each do |a4|
    out << "#{a4[:name]}       #{a4[:ttl]}     #{a4[:class]}   AAAA    #{a4[:host]}\n"
end

out << "\n; Zone TXT Records\n" unless self.txt.empty?
self.txt.each do |tx|
    out << "#{tx[:name]}       #{tx[:ttl]}     #{tx[:class]}   TXT     #{tx[:text]}\n"
end

out << "\n; Zone SRV Records\n" unless self.srv.empty?
self.srv.each do |srv|
    out << "#{srv[:name]}      #{srv[:ttl]}    #{srv[:class]}  SRV     #{srv[:pri]} #{srv[:weight]} #{srv[:port]}      #{srv[:host]}\n"
end

out << "\n; Zone PTR Records\n" unless self.ptr.empty?
self.ptr.each do |ptr|
    out << "#{ptr[:name]}      #{ptr[:ttl]}    #{ptr[:class]}  PTR     #{ptr[:host]}\n"
end

out
    end
end
