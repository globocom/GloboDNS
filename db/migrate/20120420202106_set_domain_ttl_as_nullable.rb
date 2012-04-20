class SetDomainTtlAsNullable < ActiveRecord::Migration
    def change
        change_table :domains do |t|
            t.change :ttl, :integer, :null => true
        end
    end
end
