class AddPasswordToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password, :string, :default => "password"
  end
end
