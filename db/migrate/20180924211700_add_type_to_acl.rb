class AddTypeToAcl < ActiveRecord::Migration
  def change
    change_table :acls do |t|
      t.string :acl_type
    end
  end
end
