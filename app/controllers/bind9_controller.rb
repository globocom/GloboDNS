class Bind9Controller < ApplicationController
    include GloboDns::Config

    respond_to :html, :json
    responders :flash

    before_filter :admin?

    def index
        get_current_config
    end

    def configuration
        get_current_config
        respond_with(@current_config) do |format|
            format.html { render :text => @current_config if request.xhr? }
        end
    end

    def export
        if params['now'].try(:downcase) == 'true'
            @output, status = run_export
        elsif File.exists?(EXPORT_STAMP_FILE)
            last_update = [ Record.last_update, Domain.last_update, File.stat(EXPORT_STAMP_FILE).mtime ].max
            if Time.now > (last_update + EXPORT_DELAY)
                @output, status = run_export
            else
                @output = I18n.t('export_scheduled', :timestamp => export_timestamp(last_update + EXPORT_DELAY))
                status  = :ok
            end
        else
            @output = I18n.t('no_export_scheduled')
            status  = :ok
        end

        respond_to do |format|
            format.html { render :status => status, :layout => false } if request.xhr?
            format.json { render :status => status, :json   => { ((status == :ok) ? 'output' : 'error') => @output } }
        end
    end

    def schedule_export
        FileUtils.touch(EXPORT_STAMP_FILE)
        @output = I18n.t('export_scheduled', :timestamp => export_timestamp(File.stat(EXPORT_STAMP_FILE).mtime + EXPORT_DELAY))
        respond_to do |format|
            format.html { render :status => status, :layout => false } if request.xhr?
            format.json { render :status => status, :json   => { 'output' => @output } }
        end
    end

    private

    def get_current_config
        @master_named_conf = File.read(File.join(EXPORT_MASTER_CHROOT_DIR, EXPORT_CONFIG_FILE)).sub(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")
        @slave_named_conf  = File.read(File.join(EXPORT_SLAVE_CHROOT_DIR,  EXPORT_CONFIG_FILE)).sub(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")
    end

    def run_export
        GloboDns::Exporter.new.export_all(params['master-named-conf'],
                                          params['slave-named-conf'],
                                          :all                   => params['all'] == 'true',
                                          :keep_tmp_dir          => true,
                                          :logger                => Logger.new(sio = StringIO.new('', 'w')))
                                          # :abort_on_rndc_failure => false,
        [ sio.string, :ok ]
    rescue Exception => e
        logger.error "[ERROR] export failed: #{e}\n#{sio ? sio.string : ''}\nbacktrace:\n#{e.backtrace.join("\n")}"
        [ e.to_s, :unprocessable_entity ]
    ensure
        File.unlink(EXPORT_STAMP_FILE) rescue nil
    end

    # round up to the nearest round minute, as it's the smallest time grain
    # supported by cron jobs
    def export_timestamp(timestamp)
        Time.at((timestamp.to_i / 60 + 1) * 60)
    end
end
