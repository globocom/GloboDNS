class RenameQueryIpAddressToKey < ActiveRecord::Migration
    def up
        remove_column 'views', 'query_ip_address'
        add_column    'views', 'key', :string, :limit => 64
    end

    def down
        remove_column 'views', 'key'
        add_column 'views', 'query_ip_address', :string, :limit => 256
    end
end
