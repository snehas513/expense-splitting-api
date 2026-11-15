class Settlement < ApplicationRecord
  STATUS_TYPES = %w[pending confirmed rejected cancelled].freeze
  belongs_to :group
  belongs_to :sender,
             class_name: "User",
             foreign_key: :sender_id
  
  belongs_to :receiver,
            class_name: "User",
            foreign_key: :receiver_id

  belongs_to :creator,
           class_name: "User",
           foreign_key: :created_by_id
  
  belongs_to :acted_by,
            class_name: "User",
            foreign_key: :acted_by_id,
            optional: true

  validates :settlement_amount, numericality: { greater_than: 0 }, presence: true
  validates :status, inclusion: { in: STATUS_TYPES }
  validates :settlement_date, presence: true

  scope :confirmed, -> { where(status: "confirmed") }
  scope :pending, -> { where(status: "pending") }

  def as_json(options={})
    {
      "id": id,
      "group": group,
      "sender": sender,
      "receiver": receiver,
      "creator": creator,
      "settlement_amount": format("%.2f", settlement_amount),
      "status": status,
      "settlement_date": settlement_date.strftime("%Y-%m-%d"),
      "note": note,
      "acted_by": acted_by
    }
  end

  def pending?
    status == "pending"
  end
end