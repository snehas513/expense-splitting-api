class AddSettlementAmountPositiveCheckToSettlements < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :settlements,
                     "settlement_amount > 0",
                     name: "settlements_amount_positive"
                     
    add_check_constraint :settlements,
                     "sender_id <> receiver_id",
                     name: "settlements_sender_receiver_different"
  end
end
