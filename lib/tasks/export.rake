namespace :globodns do
  desc 'Export updates to bind servers'
  task export: :environment do

    include GloboDns::Config

    @logger = GloboDns::StringIOLogger.new(Rails.logger)

    scheduled = Schedule.run_exclusive :schedule do |s|
      s.date
    end

    if scheduled.nil?
      @logger = I18n.t('no_export_scheduled')
    elsif scheduled <= DateTime.now
      schedule_run = Schedule.run_exclusive :export do |s|
        unless s.date.nil?
          @logger.warn "There is another process running. To run export again,
          remove row #{s.id} in schedules table"
          next
        end
        # register last execution in schedule
        s.date = DateTime.now
      end
      unless schedule_run.nil?
        @logger.info 'Export Started'
        run_export
        @logger.info 'Export Finished'
      end
    else
      @logger = I18n.t('export_scheduled', timestamp: scheduled)
    end
  end

  def run_export
    exporter = GloboDns::Exporter.new
    get_current_config

    # clear schedule, because will run now
    Schedule.run_exclusive :schedule do |s|
      s.date = nil
    end

    begin
      exporter.export_all(
        @master_named_conf, @slaves_named_confs,
        all: 'false',
        keep_tmp_dir: false,
        reset_repository_on_failure: true,
        use_tmp_dir: false
      )
    rescue Exception => e
      @logger.error "[ERROR] export failed:
        #{e}\n#{exporter.logger}\nbacktrace:\n#{e.backtrace.join('\n')}"
    ensure
      Schedule.run_exclusive :export do |s|
        s.date = nil
      end
    end
  end

  def get_current_config
    bind_config = GloboDns::Config::Bind
    @master_named_conf = GloboDns::Exporter.load_named_conf(bind_config::Master::EXPORT_CHROOT_DIR, bind_config::Master::NAMED_CONF_FILE)
    @slaves_named_confs = bind_config::Slaves.map do |slave|
      GloboDns::Exporter.load_named_conf(slave::EXPORT_CHROOT_DIR, slave::NAMED_CONF_FILE) if slave_enabled?(slave)
    end
    @slaves_named_confs.compact!
  end
end
