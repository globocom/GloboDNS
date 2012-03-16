class Bind9Controller < InheritedResources::Base
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
end
