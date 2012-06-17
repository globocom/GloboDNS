require 'fileutils'
namespace :globodns do
    namespace :chroot do
        desc 'Create local chroot dir with a versioned copy of the BIND files'
        task :create => :environment do
            include GloboDns::Config
            include GloboDns::Util

            def create_chroot_dir(base)
                File.exists?(base) and raise RuntimeError.new("[ERROR] chroot dir \"#{base}\" already exists")
                FileUtils.mkdir_p(base)
                FileUtils.mkdir_p(File.join(base, 'dev'))
                FileUtils.mkdir_p(File.join(base, 'etc'))
                FileUtils.mkdir_p(File.join(base, 'etc', 'named'))
                FileUtils.mkdir_p(File.join(base, EXPORT_CONFIG_DIR))
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

                FileUtils.ln_s(Pathname.new(EXPORT_CONFIG_DIR).join(Pathname.new(EXPORT_CONFIG_FILE).basename).relative_path_from(Pathname.new(EXPORT_CONFIG_FILE).dirname), File.join(base, EXPORT_CONFIG_FILE))
                Dir.chdir(File.join(base, EXPORT_CONFIG_DIR)) do
                    FileUtils.touch(File.basename(EXPORT_CONFIG_FILE))
                    exec('git init',   'git', 'init', '.')
                    exec('git add',    'git', 'add', File.basename(EXPORT_CONFIG_FILE))
                    exec('git commit', 'git', 'commit', "--date=#{Time.local(2012, 1, 1, 0, 0, 0).to_i}", "--author=#{GIT_AUTHOR}", '-m', 'Initial commit.')
                end
            end

            create_chroot_dir(EXPORT_MASTER_CHROOT_DIR)
            create_chroot_dir(EXPORT_SLAVE_CHROOT_DIR)
        end
    end
end
