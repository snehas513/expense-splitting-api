class SettlementExpense < ApplicationRecord
  belongs_to :settlement
  belongs_to :expense

  validates :allocation_amount, numericality: { greater_than: 0 }, presence: true
end
