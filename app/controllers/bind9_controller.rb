class Bind9Controller < ApplicationController
    include GloboDns::Config

    respond_to :html, :json
    responders :flash

    before_filter :admin_or_operator?

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
        begin
            GloboDns::Exporter.new.export_all(params['master-named-conf'],
                                              params['slave-named-conf'],
                                              :all                   => params['export-all'],
                                              :keep_tmp_dir          => true,
                                              # :abort_on_rndc_failure => false,
                                              :logger                => Logger.new(sio = StringIO.new('', 'w')))

            # GloboDns::Exporter.new.export_all(params[:named_conf], :logger => Logger.new(sio = StringIO.new('', 'w')), :test_changes => false)
            @output = sio.string
            status = :ok
        rescue Exception => e
            @output = e.to_s
            logger.error "[ERROR] export failed: #{e}\n#{sio ? sio.string : ''}"
            logger.error "backtrace:\n#{e.backtrace.join("\n")}"
            status = :unprocessable_entity
        end

        respond_to do |format|
            format.html { render :status => status, :layout => false } if request.xhr?
            format.json { render :status => status,
                                 :json   => { ((status == :ok) ? 'output' : 'error') => @output } }
        end
    end

    def test
        GloboDns::Tester.new(:logger => Logger.new(sio = StringIO.new('', 'w'))).run_all
        respond_with(@output = sio.string)
    end

    private

    def get_current_config
        @master_named_conf = File.read(File.join(EXPORT_MASTER_CHROOT_DIR, EXPORT_CONFIG_FILE)).sub(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")
        @slave_named_conf  = File.read(File.join(EXPORT_SLAVE_CHROOT_DIR,  EXPORT_CONFIG_FILE)).sub(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")
    end
end
