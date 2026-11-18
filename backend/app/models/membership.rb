class Membership < ApplicationRecord
	ROLE_TYPES = %w[member admin].freeze
	STATUS_TYPES = %w[active inactive].freeze
	belongs_to :user
	belongs_to :group

	validates :role, inclusion: { in: ROLE_TYPES }
	validates :status, inclusion: { in: STATUS_TYPES }

	def as_json(options={})
		{
			"id": id,
			"user": user,
			"role": role,
			"status": status
		}
	end
end