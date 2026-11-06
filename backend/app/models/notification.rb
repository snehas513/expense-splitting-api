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
end