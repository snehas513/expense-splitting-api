class ExpenseParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :expense

  validates :share_amount, numericality: { greater_than: 0 }, presence: true

  def as_json(options={})
    {
      "id": id,
      "user": user,
      "share_amount": format("%.2f", share_amount),
    }
  end
end