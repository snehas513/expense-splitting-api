class Invitation < ApplicationRecord
  STATUS_TYPES = %w[pending accepted rejected revoked].freeze

  belongs_to :group

  belongs_to :invited_user,
             class_name: "User",
             foreign_key: :invited_user_id

  belongs_to :invited_by,
             class_name: "User",
             foreign_key: :invited_by_id

  validates :status, inclusion: {in: STATUS_TYPES }
  validates :sent_at, presence: true

  def as_json(options={})
   {
    "id": id,
    "group": group,
    "invited_user": invited_user,
    "invited_by": invited_by,
    "status": status,
    "sent_at": sent_at.iso8601,
    "responded_at": responded_at&.iso8601,
    "revoked_at": revoked_at&.iso8601
    }
  end

  def pending?
    status == "pending"
  end

end