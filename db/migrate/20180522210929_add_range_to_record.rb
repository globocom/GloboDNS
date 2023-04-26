class AddRangeToRecord < ActiveRecord::Migration
  def change
    add_column :records, :range, :string
  end
end
