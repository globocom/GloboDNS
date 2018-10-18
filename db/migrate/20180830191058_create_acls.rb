class CreateAcls < ActiveRecord::Migration
  def change
    create_table :acls do |t|
      t.column :name, :string, null: false, unique: true
      t.column :content, :string

      t.timestamps null: false
    end
  end
end
