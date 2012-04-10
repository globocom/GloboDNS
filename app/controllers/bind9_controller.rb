class Bind9Controller < ApplicationController
    include GloboDns::Config

    respond_to :html, :json

    def index
        get_current_config
    end

    def configuration
        get_current_config
        respond_with(@current_config) do |format|
            format.html { render :text => @current_config if request.xhr? }
        end
    end

    def update_config
    end

    def export
        GloboDns::Exporter.new.export_all(params[:named_conf], :logger => Logger.new(sio = StringIO.new('', 'w')), :test_changes => false)
        respond_with(@output = sio.string) do |format|
            format.html { render :layout => !request.xhr? }
        end
    end

    def test
        GloboDns::Tester.new(:logger => Logger.new(sio = StringIO.new('', 'w'))).run_all
        respond_with(@output = sio.string)
    end

    private

    def get_current_config
        @current_config = IO.read(File.join(BIND_CHROOT_DIR, BIND_CONFIG_FILE)).sub(/#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n/m, '')
    end
end
