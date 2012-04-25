class CreateViews < ActiveRecord::Migration
    def change
        create_table :views do |t|
            t.string     :name,         :limit => 32,  :null => false
            t.string     :clients,      :limit => 1024
            t.string     :destinations, :limit => 1024
            t.timestamps
        end

        change_table :domains do |t|
            t.integer :view_id, :null => true
        end

        change_table :domain_templates do |t|
            t.integer :view_id, :null => true
        end
    end
end
