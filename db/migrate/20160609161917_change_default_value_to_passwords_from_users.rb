class ChangeDefaultValueToPasswordsFromUsers < ActiveRecord::Migration
  def change
  	change_column :users, :password, :string, :default => "teste"
  end
end
