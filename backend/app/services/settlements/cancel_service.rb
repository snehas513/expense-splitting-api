class Settlements::CancelService < Settlements::ActionService

  def initialize(group:, settlement:, acted_by:)
    super(group: group, settlement: settlement, acted_by: acted_by, status: "cancelled")
  end

  private

  def validate_action
    validate_creator_is_actor
  end

  def validate_creator_is_actor
    return if creator.blank? || acted_by.blank?

    @errors << "Acted By must be the creator" if creator.id != acted_by.id
  end

  def send_notification
    { success: true }
  end
end

# group = Group.first
# settlement = group.settlements.pending.first
# sender = Group.first.users.second
# receiver = Group.first.users.first
# acted_by = sender


# Settlements::CancelService.new(group: group, settlement: settlement, acted_by: acted_by).call