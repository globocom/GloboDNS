class AddExportToToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :export_to, :string, array: true
  end
end
