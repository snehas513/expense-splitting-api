class Settlements::ConfirmService < Settlements::ActionService

  def initialize(group:, settlement:, acted_by:)
    super(group: group, settlement: settlement, acted_by: acted_by, status: "confirmed")
  end

  private

  def validate_action
    validate_settlement_party(type: "Creator", user: creator)
    validate_settlement_party(type: "Acted By", user: acted_by)

    validate_different_users
  end
end

# group = Group.first
# settlement = group.settlements.pending.first
# sender = Group.first.users.second
# receiver = Group.first.users.first
# acted_by = receiver


# Settlements::ConfirmService.new(group: group, settlement: settlement, acted_by: acted_by).call