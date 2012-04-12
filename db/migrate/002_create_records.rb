class CreateRecords < ActiveRecord::Migration
    def self.up
        create_table :records, :force => true do |t|
            t.integer :domain_id,   :null => false
            t.string  :name,        :null => false
            t.string  :type,        :null => false
            t.string  :content,     :null => false
            t.integer :ttl,         :null => true
            t.integer :prio

            t.timestamps
        end

        add_index :records, :domain_id
        add_index :records, :name
        add_index :records, [ :name, :type ]
    end

    def self.down
        drop_table :records
    end
end
