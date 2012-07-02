class AddQueryIpAddressToViews < ActiveRecord::Migration
    def change
        add_column 'views', 'query_ip_address', :string, :limit => 256
    end
end
