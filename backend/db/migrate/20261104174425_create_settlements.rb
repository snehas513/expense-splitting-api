class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements do |t|
      t.references :group, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.decimal :settlement_amount, precision: 12, scale: 2, null: false
      t.string :status, null: false, default: "pending"
      t.date :settlement_date, null: false
      t.text :note
      t.references :acted_by, foreign_key: { to_table: :users }

      t.timestamps null: false
    end
  end
end
