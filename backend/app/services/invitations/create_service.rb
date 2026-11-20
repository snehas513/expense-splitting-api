class Invitations::CreateService
  include GroupValidation
  attr_reader :invited_by, :group, :invited_user
  
  def initialize(invited_by:, group:, invited_user:)
    @invited_by = invited_by
    @group = group
    @invited_user = invited_user
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    
    create_invitation
    return { success: false, errors: @errors } unless @errors.empty?

    { success: true, invitation: @invitation }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_group
    validate_parties
  end

  def active_member_ids(user_ids)
    @active_member_ids = Membership.where(
      user_id: user_ids,
      group_id: group.id,
      status: "active"
    ).pluck(:user_id)
  end
  
  def active_admin_member_ids(user_ids)
    Membership.where(
      user_id: user_ids,
      group_id: group.id,
      status: "active",
      role: "admin"
    ).pluck(:user_id)
  end

  def validate_parties
    user_ids = [invited_by&.id, invited_user&.id].compact.uniq

    @active_member_ids = group.present? ? active_member_ids(user_ids) : []
    @active_admin_member_ids = group.present? ? active_admin_member_ids(user_ids) : []
    
    if invited_by.blank?
      @errors << "Invited By is required"
    elsif !invited_by.active? || !@active_admin_member_ids.include?(invited_by.id)
      @errors << "Invited by must have an active account and active admin membership in the group"
    end

    if invited_user.blank?
      @errors << "Invited User is required"
    elsif !invited_user.active?
      @errors << "Invited User must have an active account"
    elsif @active_member_ids.include?(invited_user.id)
      @errors << "Invited User is already an active member of the group"
    end

    if invited_by.present? && invited_user.present? && invited_by.id == invited_user.id
      @errors << "A user cannot invite themselves"
    end

    if group.present? && invited_user.present? && pending_invitations_for_invited_user.exists?
      @errors << "Pending invitation already exists for this group/user"
    end
  end

  def pending_invitations_for_invited_user
    Invitation.where(
      group_id: group.id,
      status: "pending",
      invited_user_id: invited_user.id
    )
  end

  def create_invitation
    Invitation.transaction do
      @invitation = group.invitations.create!(
        status: "pending",
        invited_by_id: invited_by.id,
        invited_user_id: invited_user.id,
        sent_at: Time.current
      )
      response = send_notification
     
      unless response[:success]
        @errors.concat(response[:errors])
        raise ActiveRecord::Rollback
      end
    end
  end

  def send_notification
    Notifications::CreateService.new(
      user: invited_user,
      notification_type: "group_invitation",
      message: "#{invited_by.name} invited you to join #{group.name}."
    ).call
  end

end