class Bind9Controller < ApplicationController
    include GloboDns::Config

    def index
        get_current_config
    end

    def show_config
        get_current_config
    end

    def update_config
    end

    def export
        GloboDns::Exporter.new.export_all(:logger       => Logger.new(sio = StringIO.new('', 'w')),
                                          :test_changes => false)
        @output = sio.string
        respond_to do |format|
            format.xml  { render :xml  => @output }
            format.json { render :json => @output }
            format.html
        end
    end

    def test
        GloboDns::Tester.new(:logger => Logger.new(sio = StringIO.new('', 'w'))).run_all
        @output = sio.string
        respond_to do |format|
            format.xml  { render :xml  => {'output' => @output}.to_xml  }
            format.json { render :json => {'output' => @output}.to_json }
            format.html
        end
    end

    private

    def get_current_config
        @current_config = IO.read(File.join(BIND_CHROOT_DIR, BIND_CONFIG_FILE))
    end
end
