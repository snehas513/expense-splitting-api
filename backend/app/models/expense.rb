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
  validate :expense_date_cannot_be_in_the_future

  scope :active, -> { where(status: "active") }
  scope :recent_first, -> { order(expense_date: :desc, id: :desc) }
  scope :for_group, -> (group_id) { where(group_id: group_id) }
  scope :after_cursor, ->(cursor_date, cursor_id) {
    where("expense_date < ?", cursor_date)
      .or(
        where("expense_date = ? AND id < ?", cursor_date, cursor_id)
      )
    }
    
  def as_json(options = {})
    {
      "group": group,
      "payer": payer,
      "creator": creator,
      "amount": amount,
      "description": description,
      "note": note,
      "status": status,
      "expense_date": expense_date,
      "expense_participants": expense_participants
    }
  end

  private

  def expense_date_cannot_be_in_the_future
    return if expense_date.blank?

    if expense_date > Date.current
      errors.add(:expense_date, "cannot be in the future")
    end
  end
end