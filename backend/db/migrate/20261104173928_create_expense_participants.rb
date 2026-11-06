class CreateExpenseParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :expense_participants do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :share_amount, precision: 12, scale: 2, null: false

      t.timestamps null: false
    end
    add_index :expense_participants,
        [:expense_id, :user_id],
        unique: true,
        name: "index_expense_participants_on_expense_and_user"
  end
end
