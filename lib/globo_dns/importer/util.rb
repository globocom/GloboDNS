String.class_eval do
    def strip_quotes
        self.sub(/^['"]?(.*?)['"]?$/, '\1')
    end
end

module NamedConf
    module Util
        def included(base)
            STDERR.puts "including #{self.name}::InstanceMethods"
            base.send(:include, InstanceMethods)
        end

        module InstanceMethods
            def directory
                @directory
            end

            def directory=(val)
                @directory = val
            end
        end
	end
end
