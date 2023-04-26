class RemoveDisabledFromDomain < ActiveRecord::Migration
  def change
    remove_column :domains, :disabled
  end
end
