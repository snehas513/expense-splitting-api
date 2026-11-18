class Invitations::RejectService < Invitations::RequestValidationService
  
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

  def update_invitation
    invitation.update!(
      status: "rejected",
      responded_at: Time.current
    )
  end

end