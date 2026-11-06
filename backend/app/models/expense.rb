class Expense < ApplicationRecord
  STATUS_TYPES = %w[active deleted].freeze
  belongs_to :group
  belongs_to :payer,
           class_name: "User",
           foreign_key: :paid_by_id
  belongs_to :creator,
           class_name: "User",
           foreign_key: :created_by_id
  has_many :expense_participants
  has_many :participants, through: :expense_participants, source: :user
  validates :description, presence: true
  validates :status, inclusion: { in: STATUS_TYPES }
  validates :expense_date, presence: true
  validates :amount, numericality: { greater_than: 0 }, presence: true
end