class Settlements::RejectService < Settlements::ActionService

  def initialize(group:, settlement:, acted_by:)
    super(group: group, settlement: settlement, acted_by: acted_by, status: "rejected")
  end

  private

  def validate_action
    validate_settlement_party(type: "Creator", user: creator)
    validate_settlement_party(type: "Acted By", user: acted_by)

    validate_different_users
  end

  def send_notification
    Notifications::CreateService.new(
      user: settlement.creator,
      notification_type: "settlement_rejection",
      message: "#{settlement.acted_by.name} rejected your settlement request of ₹#{settlement.settlement_amount} in #{settlement.group.name}."
    ).call
  end
end

# group = Group.first
# settlement = group.settlements.pending.first
# sender = Group.first.users.second
# receiver = Group.first.users.first
# acted_by = receiver


# Settlements::RejectService.new(group: group, settlement: settlement, acted_by: acted_by).call