class CreateDomains < ActiveRecord::Migration
    def self.up
        create_table :domains, :force => true do |t|
            t.integer :user_id
            t.string  :name
            t.string  :master
            t.integer :last_check
            t.string  :type,           :null => false
            t.integer :notified_serial
            t.string  :account
            t.integer :ttl,            :null => false
            t.text    :notes
            t.timestamps
        end

        add_index :domains, :name
    end

    def self.down
        drop_table :domains
    end
end
