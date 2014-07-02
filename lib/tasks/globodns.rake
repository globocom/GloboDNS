require 'fileutils'
require 'pathname'
namespace :globodns do
    namespace :chroot do
        desc 'Create local chroot dir with a versioned copy of the BIND files'
        task :create => :environment do
            include GloboDns::Config
            include GloboDns::Util

            def create_chroot_dir(base, zones_dir, named_conf_file, named_conf_link)
                File.exists?(base) and raise RuntimeError.new("[ERROR] chroot dir \"#{base}\" already exists")
                FileUtils.mkdir_p(base)
                FileUtils.mkdir_p(File.join(base, 'dev'))
                FileUtils.mkdir_p(File.join(base, 'etc'))
                FileUtils.mkdir_p(File.join(base, 'etc', 'named'))
                FileUtils.mkdir_p(File.join(base, zones_dir))
                FileUtils.mkdir_p(File.join(base, 'etc', 'pki'))
                FileUtils.mkdir_p(File.join(base, 'etc', 'pki', 'dnssec-keys'))
                FileUtils.mkdir_p(File.join(base, 'usr'))
                FileUtils.mkdir_p(File.join(base, 'usr', 'lib'))
                FileUtils.mkdir_p(File.join(base, 'usr', 'lib', 'bind'))
                FileUtils.mkdir_p(File.join(base, 'usr', 'lib64'))
                FileUtils.mkdir_p(File.join(base, 'usr', 'lib64', 'bind'))
                FileUtils.mkdir_p(File.join(base, 'var'))
                FileUtils.mkdir_p(File.join(base, 'var', 'log'))
                FileUtils.mkdir_p(File.join(base, 'var', 'named'))
                FileUtils.mkdir_p(File.join(base, 'var', 'named', 'dynamic'))
                FileUtils.mkdir_p(File.join(base, 'var', 'run'))
                FileUtils.mkdir_p(File.join(base, 'var', 'run', 'named'))
                FileUtils.mkdir_p(File.join(base, 'var', 'tmp'))

        		base_path = Pathname.new base
                named_file_path = Pathname.new File.join(base, named_conf_file)
                named_link_path = Pathname.new File.join(base, named_conf_link)
        		Dir.chdir(base) do
                    FileUtils.touch named_file_path.relative_path_from(base_path).to_s, :verbose => true
    
                    FileUtils.ln_s named_file_path.relative_path_from(named_link_path.parent).to_s, \
                        named_link_path.relative_path_from(base_path).to_s, :verbose => true
        		end

                Dir.chdir(File.join(base, zones_dir)) do
                    exec('git init',   'git', 'init', '.')
                    exec('git add',    'git', 'add', '.')
                    exec('git commit', 'git', 'commit', "--date=#{Time.local(2012, 1, 1, 0, 0, 0).to_i}", "--author=#{GIT_AUTHOR}", '-m', 'Initial commit.')
                end
            end

            create_chroot_dir(EXPORT_MASTER_CHROOT_DIR, BIND_MASTER_ZONES_DIR, BIND_MASTER_NAMED_CONF_FILE, BIND_MASTER_NAMED_CONF_LINK)
            create_chroot_dir(EXPORT_SLAVE_CHROOT_DIR,  BIND_SLAVE_ZONES_DIR,  BIND_SLAVE_NAMED_CONF_FILE,  BIND_SLAVE_NAMED_CONF_LINK) if SLAVE_ENABLED?
        end
    end
end
