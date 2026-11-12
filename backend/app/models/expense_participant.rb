class ExpenseParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :expense

  validates :share_amount, numericality: { greater_than: 0 }, presence: true

  def as_json(options={})
    {
      "user": user,
      "share_amount": share_amount,
    }
  end
end