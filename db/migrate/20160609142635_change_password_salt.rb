class ChangePasswordSalt < ActiveRecord::Migration
  def change
  	rename_column :users, :password_salt, :password
  end
end
