class CreateCaas < ActiveRecord::Migration
  def change
    create_table :caas do |t|

      t.timestamps null: false
    end
  end
end
