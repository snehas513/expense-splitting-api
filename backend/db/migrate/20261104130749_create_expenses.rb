class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :group, null: false, foreign_key: true
      t.references :paid_by,
                   null: false,
                   foreign_key: { to_table: :users }
      t.references :created_by,
                   null: false,
                   foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :description, null: false
      t.text :note
      t.string :status, null: false, default: "active"
      t.date :expense_date, null: false

      t.timestamps null: false
    end
  end
end
