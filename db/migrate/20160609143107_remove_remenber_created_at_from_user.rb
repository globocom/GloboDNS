class RemoveRemenberCreatedAtFromUser < ActiveRecord::Migration
  def change
  	remove_column :users, :remember_created_at, :string
  end
end
