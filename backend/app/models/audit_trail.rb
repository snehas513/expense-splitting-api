class AuditTrail < ApplicationRecord
  belongs_to :user
  belongs_to :auditable, polymorphic: true
end
