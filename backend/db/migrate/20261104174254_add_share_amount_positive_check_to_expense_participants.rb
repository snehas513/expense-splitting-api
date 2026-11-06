class AddShareAmountPositiveCheckToExpenseParticipants < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :expense_participants,
                     "share_amount > 0",
                     name: "expense_participants_share_positive"
  end
end
