require 'test_helper'

class ExporterTest < ActiveSupport::TestCase
    include GloboDns::Config
    include GloboDns::Util

    def setup
        Dir.chdir(Rails.root.join('test'))
        @exporter = GloboDns::Exporter.new
        @options  = { :logger => Logger.new(@log_io = StringIO.new('')), :keep_tmp_dir => true, :lock_tables => false }

        set_now Time.local(2012, 3, 1, 12, 0, 0)

        # manually set timestamps of existing records to 'before' the initial export date
        yesterday = Time.now - 1.day
        assert View.update_all({'created_at' => yesterday, 'updated_at' => yesterday}).is_a?(Numeric)
        assert Domain.update_all({'created_at' => yesterday, 'updated_at' => yesterday}).is_a?(Numeric)
        assert Record.update_all({'created_at' => yesterday, 'updated_at' => yesterday}).is_a?(Numeric)

        create_mock_repository
    end

    def teardown(*args)
        unless self.passed?
            puts "[DEBUG] exporter log:"
            puts @log_io.string
            puts
        end
    end

    test 'initial' do
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'initial'))
    end

    test 'serial' do
        export

        # update a few records and domains
        set_now Time.local(2012, 3, 2, 12, 0, 0)
        assert records(:dom1_ns).touch
        assert records(:dom1_cname2).touch
        assert records(:dom2_soa).update_attribute('minimum', 7212)
        assert domains(:dom5).update_attribute('ttl', 86415)
        assert views(:view1).touch
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'serial1'))

        # update the time stamp to a few hours later so that we're still in the same day;
        set_now Time.local(2012, 3, 2, 18, 0, 0)
        assert records(:dom1_a1).touch
        assert records(:dom1_cname1).update_attribute('name', 'host1cname')
        assert records(:dom3_ns).update_attribute('content', 'updated-ns3.example.com.')
        assert domains(:dom4).touch
        assert domains(:view1_dom2).update_attribute('ttl', 86422)
        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'serial2'))
    end

    test 'create domain' do
        export
        set_now Time.local(2012, 3, 2, 12, 0, 0)

        # master
        assert (master = Domain.new(:name => 'domain7.example.com', :authority_type => Domain::MASTER, :ttl => 86407, :primary_ns => 'ns7.example.com.', :contact => 'root7.example.com.', :refresh => 10807, :retry => 3607, :expire => 604807, :minimum => 7207)).save
        assert master.ns_records.new(:name => '@', :content => 'ns').save
        assert master.mx_records.new(:name => '@', :content => 'mail', :prio => 17).save
        assert master.a_records.new(:name => 'ns', :content => '10.0.7.1').save
        assert master.a_records.new(:name => 'mail', :content => '10.0.7.2').save
        assert master.a_records.new(:name => 'host1', :content => '10.0.7.3').save
        assert master.a_records.new(:name => 'host2', :content => '10.0.7.4').save
        assert master.a_records.new(:name => 'host2other', :content => '10.0.7.4').save
        assert master.cname_records.new(:name => 'host1alias', :content => 'host1').save
        assert master.cname_records.new(:name => 'host2alias', :content => 'host2.domain7.example.com.').save
        assert master.txt_records.new(:name => 'txt', :ttl => 86417, :content => 'sample content for txt record').save

        # slave
        assert Domain.new(:name => 'domain8.example.com', :authority_type => Domain::SLAVE, :master => '10.0.8.1', :ttl => 86408).save

        # reverse
        assert (new_reverse = Domain.new(:name => '7.0.10.in-addr.arpa', :authority_type => Domain::MASTER, :ttl => 86407, :primary_ns => 'ns7.example.com.', :contact => 'root7.example.com.', :refresh => 10807, :retry => 3607, :expire => 604807, :minimum => 7207)).save
        assert new_reverse.ns_records.new(:name => '@', :content => 'ns7.example.com.').save
        assert new_reverse.ptr_records.new(:name => '1', :content => 'ns.domain7.example.com.').save
        assert new_reverse.ptr_records.new(:name => '2', :content => 'mail.domain7.example.com.').save
        assert new_reverse.ptr_records.new(:name => '3', :content => 'host1.domain7.example.com.').save
        assert new_reverse.ptr_records.new(:name => '4', :content => 'host2.domain7.example.com.').save

        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'create_domain'))
    end

    test 'delete domain' do
        export
        set_now Time.local(2012, 3, 2, 12, 0, 0)

        set_now Time.local(2012, 3, 2, 12, 0, 0)
        assert domains(:dom1).destroy
        assert domains(:dom6).destroy
        assert domains(:rev1).destroy

        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'delete_domain'))
    end

    test 'update_domain' do
        export
        set_now Time.local(2012, 3, 2, 12, 0, 0)

        # create records
        assert domains(:dom1).a_records.new(:name => 'new-host3', :ttl => 86411, :content => '10.0.1.5').save
        assert domains(:dom3).a_records.new(:name => 'new-host1', :ttl => 86413, :content => '10.0.3.1').save
        assert domains(:dom3).cname_records.new(:name => 'new-host1alias', :content => 'new-host1').save
        assert domains(:dom3).txt_records.new(:name => 'new-txt', :content => 'meaningless content').save
        assert domains(:rev1).ptr_records.new(:name => '5', :content => 'new-host3.domain1.example.com.').save
        assert domains(:rev1).ptr_records.new(:name => '6', :content => 'nohost.nowhere.com.').save

        # delete records
        assert records(:dom1_a2).destroy
        assert records(:dom2_mx).destroy
        assert records(:dom2_a1).destroy
        assert records(:dom2_a2).destroy

        # update records
        assert records(:dom1_ns).update_attributes(:content => 'new-ns')
        assert records(:dom1_mx).update_attributes(:content => 'new-mx', :prio => 21)
        assert records(:dom1_a_ns).update_attributes(:name => 'new-ns')
        assert records(:dom1_a1).update_attributes(:name => 'new-host1', :ttl => 86421)
        assert records(:dom1_cname1).update_attributes(:name => 'new-cname1', :content => 'new-host1')
        assert records(:rev1_a_ns).update_attributes(:content => 'new-ns.domain1.example.com.')
        assert records(:rev1_a1).update_attributes(:content => 'new-host1.domain1.example.com.')
        assert records(:rev1_a2).update_attributes(:content => 'invalid2.domain1.example.com.')

        # update domain attributes
        assert domains(:dom4).update_attributes(:name => 'new-domain4.example.com')
        assert domains(:dom5).update_attributes(:ttl => 86415)
        assert domains(:dom6).update_attributes(:master => '10.0.6.2')

        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'update_domain'))
    end

    test 'create view' do
        assert (view   = View.new(:name => 'viewthree', :clients => '10.0.3.0/24')).save
        assert (master = Domain.new(:name => 'domain1.view3.example.com', :view_id => view.id, :authority_type => Domain::MASTER, :ttl => 86413, :primary_ns => 'ns3.example.com.', :contact => 'root3.example.com.', :refresh => 10813, :retry => 3613, :expire => 604813, :minimum => 7213)).save
        assert master.ns_records.new(:name => '@', :content => 'ns3.example.com.').save
        assert master.a_records.new(:name => 'host1', :content => '10.1.3.1').save
        assert master.a_records.new(:name => 'host2', :content => '10.1.3.2').save
        assert (reverse = Domain.new(:name => '3.1.10.in-addr.arpa', :view_id => view.id, :authority_type => Domain::MASTER, :ttl => 86414, :primary_ns => 'ns4.example.com.', :contact => 'root4.example.com.', :refresh => 10814, :retry => 3614, :expire => 604814, :minimum => 7214)).save
        assert reverse.ns_records.new(:name => '@', :content => 'ns4.example.com.').save
        assert reverse.ptr_records.new(:name => '1', :content => 'host1.domain1.view3.example.com.').save
        assert reverse.ptr_records.new(:name => '2', :content => 'host2.domain1.view3.example.com.').save

        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'create_view'))
    end

    test 'delete view' do
        assert views(:view1).destroy

        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'delete_view'))
    end

    test 'update view' do
        view = views(:view1)
        assert view.update_attribute('name', 'newviewone')

        assert (domain3 = view.domains.new(:name => 'domain3.view1.example.com', :authority_type => Domain::MASTER, :ttl => 86413, :primary_ns => 'ns3.example.com.', :contact => 'root3.example.com.', :refresh => 10813, :retry => 3613, :expire => 604813, :minimum => 7213)).save
        assert domain3.ns_records.new(:name => '@', :content => 'ns3.example.com.').save
        assert domain3.a_records.new(:name => 'host1', :content => '10.1.3.1').save
        assert domain3.a_records.new(:name => 'host2', :content => '10.1.3.2').save

        assert (slave4 = view.domains.new(:name => 'domain4.view1.example.com', :authority_type => Domain::SLAVE, :master => '10.1.4.1')).save

        assert (reverse3 = view.domains.new(:name => '3.1.10.in-addr.arpa', :authority_type => Domain::MASTER, :ttl => 86413, :primary_ns => 'ns3.example.com.', :contact => 'root3.example.com.', :refresh => 10813, :retry => 3613, :expire => 604813, :minimum => 7213)).save
        assert reverse3.ns_records.new(:name => '@', :content => 'ns3.example.com.').save
        assert reverse3.ptr_records.new(:name => '1', :content => 'host1.domain3.view1.example.com.').save
        assert reverse3.ptr_records.new(:name => '2', :content => 'host2.domain3.view1.example.com.').save

        assert domains(:view1_dom2).destroy

        domain1 = domains(:view1_dom1)
        assert domain1.update_attributes({:name => 'new-domain1.view1.example.com', :ttl => 86421})
        assert domain1.a_records.find{|rec| rec.name == 'host2'}.destroy
        assert domain1.a_records.find{|rec| rec.name == 'host3'}.update_attributes('name' => 'new-host3')
        assert domain1.a_records.new(:name => 'host4', :content => '10.1.1.4').save
        assert domain1.mx_records.new(:name => '@', :content => 'host4', :prio => 10).save

        export
        compare_named_files(File.join(Rails.root, 'test', 'mock', 'named_expected', 'update_view'))
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

    def set_now(now)
        Time.instance_variable_set('@__now', now)
        def Time.now
            Time.instance_variable_get('@__now')
        end
    end
end
