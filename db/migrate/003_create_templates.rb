class CreateTemplates < ActiveRecord::Migration
    def self.up
        create_table :domain_templates do |t|
            t.string  :name
            t.integer :ttl, :null => false
            t.timestamps
        end

        create_table :record_templates do |t|
            t.integer :domain_template_id
            t.string  :name
            t.string  :record_type,      :null => false
            t.string  :content,          :null => false
            t.integer :ttl,              :null => false
            t.integer :prio
            t.timestamps
        end
    end

    def self.down
        drop_table :domain_templates
        drop_table :record_templates
    end
end
