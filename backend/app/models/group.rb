class Group < ApplicationRecord
  STATUS_TYPES = %w[active archived deleted].freeze

  has_many :memberships
  has_many :users, through: :memberships

  has_many :expenses
  has_many :settlements
  has_many :invitations

  validates :name, presence: true
  validates :status, inclusion: { in: STATUS_TYPES }

  def active?
    status == "active"
  end

  def as_json(options = {})
    {
      "name": name,
      "description": description,
      "status": status,
    }
  end
end
