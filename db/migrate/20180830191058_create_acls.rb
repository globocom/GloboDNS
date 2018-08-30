class CreateAcls < ActiveRecord::Migration
  def change
    create_table :acls do |t|

      t.timestamps null: false
    end
  end
end
