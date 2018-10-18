class CreateAclRelationships < ActiveRecord::Migration
  def change
    create_table :acl_relationships do |t|
      t.integer "acl_id"
      t.integer "child_id"

      t.timestamps null: false
    end
  end
end
