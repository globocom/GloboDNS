class AddWeightAndPortToRecordTemplate < ActiveRecord::Migration
  def change
  	add_column :record_templates, :weight, :integer
  	add_column :record_templates, :port, :integer
  end
end
