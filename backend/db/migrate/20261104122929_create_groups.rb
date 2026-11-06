class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "active"

      t.timestamps null: false
    end
  end
end