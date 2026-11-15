class Settlements::ActionService
  attr_reader :group, :settlement, :acted_by, :creator, :sender, :receiver, :status

  def initialize(group:, settlement:, acted_by:, status:)
    @group = group
    @settlement = settlement
    @acted_by = acted_by
    @status = status
    @errors = []
  end

  def call
    return { success: false, errors: ["Group is required"] } if group.blank?
    return { success: false, errors: ["Settlement is required"] } if settlement.blank?

    group.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
     
      begin
        update_settlement
        { success: true, settlement: settlement }
      rescue ActiveRecord::RecordInvalid => e
        { success: false, errors: e.record.errors.full_messages }
      end
    end
  end

  private

  def validate
    validate_group
    return unless validate_settlement

    user_ids = [acted_by&.id, sender&.id, receiver&.id, creator&.id].compact.uniq
    @active_member_ids = active_member_ids(user_ids)

    validate_active_users
    validate_action
  end

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def validate_settlement
    if settlement.blank?
      @errors << "Settlement is required"
      return false
    elsif !settlement.pending?
      @errors << "Settlement must be pending"
      return false
    elsif settlement.group_id != group.id
      @errors << "Settlement must belong to the group"
      return false
    end

    @creator = settlement.creator
    @sender = settlement.sender
    @receiver = settlement.receiver
    true
  end
    
  def validate_different_users
    return if creator.blank? || acted_by.blank?

    @errors << "Creator and Acted By must be different users" if creator.id == acted_by.id
  end

  def active_member_ids(user_ids)
    Membership.where(
      user_id: user_ids,
      group_id: group.id,
      status: "active"
    ).pluck(:user_id)
  end

  def validate_active_user(type:, user:)
    if user.blank?
      @errors << "#{type} is required"
      return
    end

    @errors << "#{type} must have an active account and active membership in the group" unless user.active? &&
      @active_member_ids.include?(user.id)
  end

  def validate_active_users
    validate_active_user(type: "Creator", user: creator)
    validate_active_user(type: "Acted By", user: acted_by)
    validate_active_user(type: "Sender", user: sender)
    validate_active_user(type: "Receiver", user: receiver)
  end

  def validate_settlement_party(type:, user:)
    return if user.blank? || sender.blank? || receiver.blank?

    unless [sender.id, receiver.id].include?(user.id)
      @errors << "#{type} must be either the sender or receiver"
    end
  end

  def validate_action
    raise NotImplementedError
  end

  def update_settlement
    settlement.update!(status: status, acted_by: acted_by)
  end

end