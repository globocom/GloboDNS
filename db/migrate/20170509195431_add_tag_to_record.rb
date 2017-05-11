class AddTagToRecord < ActiveRecord::Migration
  def change
  	add_column :records, :tag, :string
  	add_column :record_templates, :tag, :string
  end
end
