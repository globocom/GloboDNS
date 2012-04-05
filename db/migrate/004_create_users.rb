class CreateUsers < ActiveRecord::Migration
    def self.up
        create_table :users, :force => true do |t|
            t.string   :login
            t.string   :email
            t.string   :encrypted_password,       :null => false, :limit => 128
            t.string   :password_salt,            :null => false, :limit => 128
            t.string   :role,                                     :limit =>  1
            t.string   :authentication_token
            t.datetime :remember_created_at
            t.timestamps
        end
    end

    def self.down
        drop_table :users
    end
end
