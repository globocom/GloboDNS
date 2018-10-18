class CreateViewAcls < ActiveRecord::Migration
  def change
    create_table :view_acls do |t|
      t.references :view, index: true, foreign_key: true
      t.references :acl, index: true, foreign_key: true
      t.boolean :denied, default: false

      t.timestamps null: false
    end
  end
end
