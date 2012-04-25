require 'test_helper'

class ExporterTest < ActiveSupport::TestCase
    include GloboDns::Config
    include GloboDns::Util

    def setup
        Dir.chdir(Rails.root.join('test'))
        @exporter = GloboDns::Exporter.new
        @options  = { :logger => Logger.new(STDERR), :keep_tmp_dir => true, :lock_tables => false }
    end

    test 'export' do
        create_mock_repository
        set_now Time.local(2012, 3, 1, 12, 0, 0)
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'initial'))

        puts "------------------------------------------------------------"
        return

        change_named_conf
        set_now Time.local(2012, 3, 1, 17, 0, 0)
        change_db
        set_now Time.local(2012, 3, 1, 18, 0, 0)
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'final'))
    end

    private

    def export
        begin
            spawn_named
            @exporter.export_all(mock_named_conf_content, @options.merge(:set_timestamp => Time.now))
        rescue Exception => e
            STDERR.puts "[ERROR] #{e}", e.backtrace.join("\n")
            STDERR.puts "[ERROR] named output:", @named_output.read if @named_output
        ensure
            @named_output.close
            @named_input.close
            kill_named
        end
    end

    def mock_named_conf_file
        @mock_named_conf_file ||= File.join(Rails.root, 'test', 'mock', 'named.conf')
    end

    def mock_named_conf_content
        @mock_named_conf_content ||= IO::read(mock_named_conf_file)
    end

    def spawn_named
        @named_output, @named_input = IO::pipe
        @named_pid = spawn(Binaries::SUDO, Binaries::NAMED, '-g', '-p', BIND_PORT, '-f', '-c', BIND_CONFIG_FILE, '-t', BIND_CHROOT_DIR, '-u', BIND_USER, [:out, :err] => @named_input)
    end

    def kill_named
        exec('kill named', Binaries::SUDO, 'kill', @named_pid.to_s)
        Process.wait(@named_pid, Process::WNOHANG)
    end

    def create_mock_repository
        named_dir = File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR)
        FileUtils.rm_r(named_dir, :force => true, :secure => true)
        FileUtils.mkdir(named_dir)
        FileUtils.cp(mock_named_conf_file, named_dir)
        Dir.chdir(named_dir) do
            timestamp = Time.utc(2012, 1, 1, 0, 0, 0)
            exec('git init', Binaries::GIT, 'init')
            FileUtils.touch('.keep')
            exec('git add .keep', Binaries::GIT, 'add', '.keep')
            exec('git status', Binaries::GIT, 'status')
            exec('git initial commit', Binaries::GIT, 'commit', "--date=#{timestamp}", '-m', 'Initial commit')
            File.utime(timestamp, timestamp, *(Dir.glob('**/*', File::FNM_DOTMATCH).reject{|file| file == '..' || file[-3, 3] == '/..' || file[-2, 2] == '/.' }))
        end
    end

    def compare_named_files(reference_dir)
        export_dir  = File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR)
        diff_output = exec('diff -r', 'diff', '-r', '-x', '.keep', '-x', '.git', reference_dir, export_dir)
        assert diff_output.blank?
    end

    def change_named_conf
        @mock_named_conf_content = 
            "# starting test comment\n" +
            @mock_named_conf_content.sub(/^(logging {)/, "# internal test comment\n\\1").
                                     gsub(/^\s*#.*\n/, '') +
            "# ending test comment\n"
    end

    def change_db
        # tweak timestamps of existing records
        now       = Time.now - 1.day
        yesterday = now - 1.day
        assert Record.update_all({'created_at' => yesterday, 'updated_at' => yesterday}).is_a?(Fixnum)

        # update the attributes of a few records
        assert records(:dom1_ns).update_attributes(:content => 'new-ns')
        assert records(:dom1_mx).update_attributes(:name => 'new-mx', :prio => 123)
        assert records(:dom1_a_ns).update_attributes(:name => 'new-ns')
        assert records(:dom1_a1).update_attributes(:name => 'new-host1', :ttl => 86411)
        assert records(:dom1_cname1).update_attributes(:name => 'new-cname1', :content => 'anyname.example.com.')
        assert records(:rev1_a_ns).update_attributes(:content => 'new-ns.domain1.example.com.')
        assert records(:rev1_a1).update_attributes(:content => 'new-host1.domain1.example.com.')

        # create a few records on existing domains
        assert domains(:dom1).a_records.new(:name => 'new-host3', :ttl => 86412, :content => '10.0.1.5').save
        assert domains(:dom3).a_records.new(:name => 'new-host1', :ttl => 86431, :content => '10.0.3.1').save
        assert domains(:dom3).cname_records.new(:name => 'new-host1alias', :content => 'new-host1').save
        assert domains(:dom3).txt_records.new(:name => 'new-txt', :content => 'meaningless content').save
        assert domains(:rev1).ptr_records.new(:name => '5', :content => 'new-host3.domain1.example.com.').save

        # delete a few records from existing domains
        assert records(:dom2_mx).destroy
        assert records(:dom2_a1).destroy
        assert records(:dom2_a2).destroy

        # update a few domains
        assert domains(:dom4).update_attributes(:name => 'new-domain4.example.com', :ttl => 86004)

        # delete a domain
        assert domains(:dom5).destroy

        # create a new slave domain
        assert Domain.new(:name => 'new-slavedomain7.example.com', :type => Domain::TYPE_SLAVE, :master => '10.0.7.1', :ttl => 86407).save

        # create a new master domain with new records
        assert (new_master = Domain.create(:name => 'new-domain8.example.com', :type => Domain::TYPE_MASTER, :ttl => 86408, :primary_ns => 'ns8.example.com.', :contact => 'root8.example.com.', :refresh => 10808, :retry => 3608, :expire => 604808, :minimum => 7208)).save
        assert new_master.ns_records.new(:name => '@', :content => 'new-ns').save
        assert new_master.mx_records.new(:name => '@', :content => 'new-mail', :prio => 18).save
        assert new_master.a_records.new(:name => 'new-ns', :content => '10.0.8.1').save
        assert new_master.a_records.new(:name => 'new-mail', :content => '10.0.8.2').save
        assert new_master.a_records.new(:name => 'new-host1', :content => '10.0.8.3').save
        assert new_master.a_records.new(:name => 'new-host2', :content => '10.0.8.4').save
        assert new_master.a_records.new(:name => 'new-host2-anothername', :content => '10.0.8.4').save
        assert new_master.cname_records.new(:name => 'new-host1alias', :content => 'new-host1').save
        assert new_master.cname_records.new(:name => 'new_host2alias', :content => 'new-host2.new-domain8.example.com.').save
        assert new_master.txt_records.new(:name => 'new-txt', :ttl => 86418, :content => 'sample content for txt record').save

        # create the reverse domains for the new domains and records
        assert (new_reverse = Domain.create(:name => '3.0.10.in-addr.arpa', :type => Domain::TYPE_MASTER, :ttl => 86403, :primary_ns => 'ns3.example.com.', :contact => 'root3.example.com.', :refresh => 10803, :retry => 3603, :expire => 604803, :minimum => 7203)).save
        assert new_reverse.ns_records.new(:name => '@', :content => 'ns3.example.com.').save
        assert new_reverse.ptr_records.new(:name => '1', :content => 'new-host1.domain3.example.com.').save

        assert (new_reverse = Domain.create(:name => '8.0.10.in-addr.arpa', :type => Domain::TYPE_MASTER, :ttl => 86408, :primary_ns => 'ns8.example.com.', :contact => 'root8.example.com.', :refresh => 10808, :retry => 3608, :expire => 604808, :minimum => 7208)).save
        assert new_reverse.ns_records.new(:name => '@', :content => 'ns8.example.com.').save
        assert new_reverse.ptr_records.new(:name => '1', :content => 'new-ns.new-domain8.example.com.').save
        assert new_reverse.ptr_records.new(:name => '2', :content => 'new-mail.new-domain8.example.com.').save
        assert new_reverse.ptr_records.new(:name => '3', :content => 'new-host1.new-domain8.example.com.').save
        assert new_reverse.ptr_records.new(:name => '4', :content => 'new-host2.new-domain8.example.com.').save
    end

    def set_now(now)
        Time.instance_variable_set('@__now', now)
        def Time.now
            Time.instance_variable_get('@__now')
        end
    end
end
