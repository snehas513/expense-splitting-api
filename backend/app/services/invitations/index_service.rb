class Invitations::IndexService
  attr_reader :group, :user
  
  def initialize(group:, user:)
    @group = group
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
    validate_group
    validate_user
  end

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end

    return if user.blank? || group.blank?

    unless Membership.where(
        user_id: user.id,
        group_id: group.id,
        role: "admin",
        status: "active"
      ).exists?
      @errors << "User is not an active admin member of the group"
    end
  end

  def fetch_invitations
    @invitations = group.invitations.pending
  end
end