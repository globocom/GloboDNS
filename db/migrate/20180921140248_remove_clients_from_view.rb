class RemoveClientsFromView < ActiveRecord::Migration
  def change
    remove_column :views, :clients, :string
  end
end
