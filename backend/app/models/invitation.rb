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
end