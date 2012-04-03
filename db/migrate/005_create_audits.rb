class CreateAudits < ActiveRecord::Migration
    def self.up
        drop_table :audits
        create_table :audits, :force => true do |t|
            t.integer  :auditable_id
            t.string   :auditable_type
            t.integer  :association_id
            t.string   :association_type
            t.integer  :user_id
            t.string   :user_type
            t.string   :username
            t.string   :remote_address
            t.string   :action
            t.text     :audited_changes
            t.string   :comment
            t.integer  :version, :default => 0
            t.datetime :created_at,
        end

        add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
        add_index :audits, [:association_id, :association_type], :name => 'association_index'
        add_index :audits, [:user_id, :user_type], :name => 'user_index'
        add_index :audits, :created_at  
    end

    def self.down
        drop_table :audits
    end
end
