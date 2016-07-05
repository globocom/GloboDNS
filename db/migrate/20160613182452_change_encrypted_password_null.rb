class ChangeEncryptedPasswordNull < ActiveRecord::Migration
  def change
  	change_column :users, :encrypted_password, :string, :null => true
  end
end
