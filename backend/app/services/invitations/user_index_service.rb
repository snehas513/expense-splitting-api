class Invitations::UserIndexService
  attr_reader :user
  
  def initialize(user:)
    @user = user
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    
    fetch_invitations
    { success: true, invitations: @invitations }
  end

  private

  def validate
    validate_user
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
  end

  def fetch_invitations
    @invitations = Invitation.pending.where(
      invited_user_id: user.id
    )
  end
end