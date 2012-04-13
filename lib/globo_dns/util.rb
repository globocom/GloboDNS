require 'resolv'

module GloboDns
module Util

    # similar to 'Kernel::system', but captures the STDOUT using IO::popen and
    # raises and exception if the return code is not '0' (success)
    def exec(command_id, *args)
        output = nil
        # puts "running: #{args.join(' ')}"
        IO::popen(args) do |io|
            output = io.read
        end
        $?.exitstatus == 0 or raise "[ERROR] '#{command_id}' failed: #{$?} (#{output})"
        output
    end

    def resolver
        @@resolver ||= Resolv::DNS::new(:nameserver => GloboDns::Config::NAMESERVER_HOST)
    end

end # Util
end # GloboDns
