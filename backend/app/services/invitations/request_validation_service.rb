class Invitations::RequestValidationService
  attr_reader :invitation, :user
  
  def initialize(invitation:, user:)
    @invitation = invitation
    @user = user
    @errors = []
  end

  private

  def validate_request
    validate_invitation
    validate_user

    @errors
  end

  def validate_invitation
    if invitation.blank?
      @errors << "Invitation is required"
    elsif !invitation.pending?
      @errors << "Invitation must be pending"
    elsif !invitation.group.active?
      @errors << "Group must be active"
    end
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
    return if invitation.blank? || user.blank?

    if invitation.invited_user_id != user.id
      @errors << "User is invalid"
    elsif Membership.where(
        user_id: user.id,
        group_id: invitation.group.id,
        status: "active"
      ).exists?
      @errors << "User is already an active member of the group"
    end
  end

end