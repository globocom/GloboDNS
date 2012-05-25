class ConvertBindTimeValuesToString < ActiveRecord::Migration
    def up
        change_column 'domains',           'ttl', :string, :length => 64
        change_column 'records',           'ttl', :string, :length => 64
        change_column 'domain_templates',  'ttl', :string, :length => 64
        change_column 'record_templates', 'ttl', :string, :length => 64
    end

    def down
        change_column 'domains',           'ttl', :integer
        change_column 'records',           'ttl', :integer
        change_column 'domain_templates',  'ttl', :integer
        change_column 'record_templates', 'ttl', :integer
    end
end
