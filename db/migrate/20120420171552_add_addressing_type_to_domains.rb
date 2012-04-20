class AddAddressingTypeToDomains < ActiveRecord::Migration
    def change
        change_table :domains do |t|
            t.remove :type
            t.column :authority_type,  'CHAR(1)', :null => false
            t.column :addressing_type, 'CHAR(1)', :null => false
        end
    end
end
