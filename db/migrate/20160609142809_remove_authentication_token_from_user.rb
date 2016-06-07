class RemoveAuthenticationTokenFromUser < ActiveRecord::Migration
  def change
  	remove_column :users, :authentication_token, :string
  end
end
