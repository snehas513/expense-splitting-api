class ExpenseParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :expense

  validates :share_amount, numericality: { greater_than: 0 }, presence: true
end