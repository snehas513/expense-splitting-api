class Invitations::RevokeService < Invitations::RequestValidationService
  
  def initialize(invitation:, user:)
    super(invitation: invitation, user: user)
  end

  def call
    return { success: false, errors: ["Invitation is required"] } if invitation.blank?

    invitation.with_lock do
      errors = validate_request
      return { success: false, errors: errors } unless errors.empty?
      
      update_invitation
    end

    { success: true, invitation: invitation }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
    return if invitation.blank? || user.blank?

    return if user.blank? || invitation.blank?

    unless Membership.where(
        user_id: user.id,
        group_id: invitation.group.id,
        role: "admin",
        status: "active"
      ).exists?
      @errors << "User is not an active admin member of the group"
    end
  end

  def update_invitation
    invitation.update!(
      status: "revoked",
      revoked_at: Time.current
    )
  end

end