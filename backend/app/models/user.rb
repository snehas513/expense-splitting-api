class User < ApplicationRecord
  STATUS_TYPES = %w[active deactivated].freeze
  has_many :memberships
  has_many :groups, through: :memberships

  has_many :notifications
  has_many :expense_participants

  has_many :paid_expenses,
           class_name: "Expense",
           foreign_key: :paid_by_id

  has_many :created_expenses,
           class_name: "Expense",
           foreign_key: :created_by_id

  has_many :sent_settlements,
           class_name: "Settlement",
           foreign_key: :sender_id

  has_many :received_settlements,
           class_name: "Settlement",
           foreign_key: :receiver_id

  has_many :acted_on_settlements,
           class_name: "Settlement",
           foreign_key: :acted_by_id

  has_many :received_invitations,
           class_name: "Invitation",
           foreign_key: :invited_user_id

  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :invited_by_id

  has_many :audit_trails

  validates :name, presence: true
  validates :email,
          presence: true,
          uniqueness: { case_sensitive: false },
          format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :pending_email, 
          uniqueness: { case_sensitive: false },
          format: { with: URI::MailTo::EMAIL_REGEXP },
          allow_nil: true
  has_secure_password
  validates :status, inclusion: { in: STATUS_TYPES }

  before_validation do
    self.email = email.presence&.strip&.downcase
    self.pending_email = pending_email.presence&.strip&.downcase
  end

  def active?
    status == "active"
  end
end