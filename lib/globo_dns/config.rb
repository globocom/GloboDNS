require File.expand_path('../../../config/environment',  __FILE__)

module GloboDns
module Config

    def self.load(yaml_string)
        yml = YAML::load(yaml_string)
        set_constants(yml[Rails.env])
    end

    def self.load_from_file(file = Rails.root.join('config', 'globodns.yml'))
        yml = YAML::load_file(file)
        set_constants(yml[Rails.env])
    end

    def self.set_constants(hash, module_ = self)
        hash.each do |key, value|
            if value.is_a?(Hash)
                new_module = module_.const_set(key.camelize, Module.new)
                self.set_constants(value, new_module)
            else
                module_.const_set(key.upcase, value)
            end
        end
        true
    end

end # Config
end # GloboDns
