class AuditTrail < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true

  validates :auditable_type, presence: true
  validates :auditable_id, presence: true
  validates :action, presence: true
end