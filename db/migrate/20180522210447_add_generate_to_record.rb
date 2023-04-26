class AddGenerateToRecord < ActiveRecord::Migration
  def change
    add_column :records, :generate, :boolean
  end
end
