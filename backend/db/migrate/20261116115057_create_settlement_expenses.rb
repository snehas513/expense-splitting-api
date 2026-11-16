class CreateSettlementExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :settlement_expenses do |t|
      t.references :settlement, null: false, foreign_key: true
      t.references :expense, null: false, foreign_key: true
      t.decimal :allocation_amount, precision: 12, scale: 2, null: false

      t.timestamps
    end
    add_index :settlement_expenses,
              [:settlement_id, :expense_id], 
              unique: true

    add_check_constraint :settlement_expenses,
                     "allocation_amount > 0",
                     name: "check_settlement_expenses_allocation_amount_positive"
  end
end
