class AddSiblingIdToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :sibling_id, :integer, index: true
  end
end
