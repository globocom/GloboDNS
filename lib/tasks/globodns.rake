require 'fileutils'
require 'pathname'
namespace :globodns do

    namespace :view do
        desc 'Migrate viewless zones to default view (named default), so globodns can use views'
        task :migrate => :environment do
            if defined? GloboDns::Config::ENABLE_VIEW and GloboDns::Config::ENABLE_VIEW == true
                # sets default_view to the viewless zones 
                View.disable_auditing
                view_default = View.default
                Domain.noview.each do |domain|
                    domain.view = view_default
                    domain.save
                end

                #sets default_view to viewless zone_templates
                DomainTemplate.where(view: nil).each do |domain_template|
                    domain_template.view = view_default
                    domain_template.save
                end
            end
        end
    end

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

            create_chroot_dir(Bind::Master::EXPORT_CHROOT_DIR, Bind::Master::ZONES_DIR, Bind::Master::NAMED_CONF_FILE, Bind::Master::NAMED_CONF_LINK)
            if SLAVE_ENABLED?
                Bind::Slaves.each do |slave|
                    create_chroot_dir(slave::EXPORT_CHROOT_DIR,  slave::ZONES_DIR,  slave::NAMED_CONF_FILE,  slave::NAMED_CONF_LINK)
                end
            end
        end
    end
end
