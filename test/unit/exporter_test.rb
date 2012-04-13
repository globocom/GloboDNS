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
        def Time.now; Time.local(2012, 3, 1, 12, 0, 0); end # set fake time before export
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'initial'))

        puts "------------------------------------------------------------"
        puts "------------------------------------------------------------"
        puts "------------------------------------------------------------"
        puts "------------------------------------------------------------"

        change_named_conf
        change_db
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'final'))
    end

    private

    def export
        begin
            spawn_named
            puts "[INFO] calling export_all"
            @exporter.export_all(mock_named_conf_content, @options)
            puts "[INFO] finished export_all"
        rescue Exception => e
            STDERR.puts e, e.backtrace.join("\n")
        ensure
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
        puts "starting named"
        @named_pid = spawn(Binaries::SUDO, Binaries::NAMED, '-g', '-p', BIND_PORT, '-f', '-c', BIND_CONFIG_FILE, '-t', BIND_CHROOT_DIR, '-u', BIND_USER, {:out => STDOUT, :err => STDERR})
        puts "named pid: #{@named_pid}"
    end

    def kill_named
        puts "killing process #{@named_pid}"
        exec('kill named', Binaries::SUDO, 'kill', @named_pid.to_s)
        Process.wait(@named_pid, Process::WNOHANG)
    end

    def create_mock_repository
        named_dir = File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR)
        FileUtils.rm_r(named_dir, :force => true, :secure => true)
        FileUtils.mkdir(named_dir)
        FileUtils.cp(mock_named_conf_file, named_dir)
        Dir.chdir(named_dir) do
            puts exec('git init', Binaries::GIT, 'init')
            FileUtils.touch('.keep')
            puts exec('git add .keep', Binaries::GIT, 'add', '.keep')
            puts exec('git status', Binaries::GIT, 'status')
            puts exec('git initial commit', Binaries::GIT, 'commit', '--date=2012-01-01 00:00:00 UTC', '-m', 'Initial commit')
        end
    end

    def compare_named_files(reference_dir)
        export_dir  = File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR)
        diff_output = exec('diff -r', 'diff', '-r', '-x', '.git', reference_dir, export_dir)
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
        assert records(:dom1_a1).update_attributes(:name => 'new-host1', :ttl  => 10001)
        assert records(:dom1_cname1).update_attributes(:name => 'new-cname1',  :content => 'anyname.example.com.')

        # create a few records on existing domains
        assert domains(:dom1).a_records.new(:name => 'new-host3', :ttl => 10001, :content => '10.0.1.103').save
        assert domains(:dom3).a_records.new(:name => 'new-host1', :ttl => 10021, :content => '10.0.3.101').save
        assert domains(:dom3).cname_records.new(:name => 'new-host1alias', :content => 'new-host1').save
        assert domains(:dom3).txt_records.new(:name => 'new-txt', :content => 'meaningless content').save

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

        # and finally, create a new master domain with new records
        assert (new_master = Domain.create(:name => 'new-domain8.example.com', :type => Domain::TYPE_MASTER, :ttl => 86408, :primary_ns => 'ns1.new-domain8.example.com.', :contact => 'contact.new-domain8.example.com.', :refresh => 10808, :retry => 3608, :expire => 604808, :minimum => 7208)).save
        assert new_master.ns_records.new(:name => '@', :content => 'new-ns').save
        assert new_master.mx_records.new(:name => '@', :content => 'new-mx', :prio => 11).save
        assert new_master.a_records.new(:name => 'new-ns', :content => '10.0.8.1').save
        assert new_master.a_records.new(:name => 'new-mx', :content => '10.0.8.2').save
        assert new_master.a_records.new(:name => 'new-host1', :content => '10.0.8.3').save
        assert new_master.a_records.new(:name => 'new-host2', :content => '10.0.8.4').save
        assert new_master.cname_records.new(:name => 'new-host1alias', :content => 'new-host1').save
        assert new_master.cname_records.new(:name => 'new_host2alias', :content => 'new-host2.new-domain8.example.com.').save
        assert new_master.txt_records.new(:name => 'new-txt', :content => 'sample content for txt record').save
    end
end
