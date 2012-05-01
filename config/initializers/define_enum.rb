ActiveRecord::Base.class_eval do
    def self.define_enum(symbols, attribute)
        define_method((attribute.to_s + '_str').to_sym) { self.class.const_get(attribute.to_s.pluralize.upcase.to_sym)[self.send(attribute)] }

        symbols.inject(Hash.new) do |hash, enum_sym|
            enum_str    = enum_sym.to_s
            value       = enum_str[0]
            hash[value] = enum_str

            const_set(enum_sym, value)
            define_method(enum_str.downcase + '?') { self.send(attribute) == value }
            define_method(enum_str.downcase + '!') { self.send((attribute.to_s + '=').to_sym, value) }

            hash
        end.freeze
    end
end
