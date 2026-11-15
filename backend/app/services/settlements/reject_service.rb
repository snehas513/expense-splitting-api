class Settlements::RejectService < Settlements::ActionService

  def initialize(group:, settlement:, acted_by:)
    super(group: group, settlement: settlement, acted_by: acted_by, status: "rejected")
  end

  private

  def validate_action
    validate_different_users
  end
end

# group = Group.first
# settlement = group.settlements.pending.first
# sender = Group.first.users.second
# receiver = Group.first.users.first
# acted_by = receiver


# Settlements::RejectService.new(group: group, settlement: settlement, acted_by: acted_by).call