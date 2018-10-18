class AddCountryRegionAndCityToAcl < ActiveRecord::Migration
  def change
    add_column :acls, :country, :string
    add_column :acls, :region, :string
    add_column :acls, :city, :string
  end
end
