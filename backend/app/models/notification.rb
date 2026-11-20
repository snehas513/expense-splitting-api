class Notification < ApplicationRecord
  NOTIFICATION_TYPES = %w[
    group_invitation
    settlement_request
    settlement_confirmation
    settlement_rejection
  ].freeze
  
  belongs_to :user

  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }
  validates :message, presence: true
  validates :read, inclusion: { in: [true, false] }

  scope :unread, -> { where(read: false) }

  def as_json(options={})
    {
      "id": id,
      "notification_type": notification_type,
      "message": message,
      "read": read,
      "created_at": created_at.iso8601
    }
  end
end