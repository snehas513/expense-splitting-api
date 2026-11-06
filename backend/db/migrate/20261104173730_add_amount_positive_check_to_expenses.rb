class AddAmountPositiveCheckToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :expenses,
                     "amount > 0",
                     name: "expenses_amount_positive"
  end
end
