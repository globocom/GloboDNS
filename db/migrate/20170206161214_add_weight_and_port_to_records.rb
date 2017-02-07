class AddWeightAndPortToRecords < ActiveRecord::Migration
  def change
  	add_column :records, :weight, :integer
  	add_column :records, :port, :integer
  end
end
