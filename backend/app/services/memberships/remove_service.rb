class Memberships::RemoveService
  include GroupValidation
  attr_reader :group, :admin, :user

  def initialize(group:, admin:, user:)
    @group = group
    @admin = admin
    @user = user
    @errors = []
  end

  def call
    return { success: false, errors: ["Group is required"] } if group.blank?

    group.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
      
      remove_member
    end

    { success: true, membership: @membership }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_group
    validate_admin
    validate_different_users
    validate_user
  end

  def validate_admin
    if admin.blank?
      @errors << "Admin is required"
    elsif !admin.active?
      @errors << "Admin must have an active account"
    end

    return if admin.blank? || group.blank?

    admin_membership = Membership.find_by(group_id: group.id, user_id: admin.id, status: "active", role: "admin")
    
    unless admin_membership
      @errors << "Admin is not an active admin member of the group"
    end
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end

    return if user.blank? || group.blank?

    @membership = Membership.find_by(group_id: group.id, user_id: user.id, status: "active")
    
    unless @membership
      @errors << "User is not an active member of the group"
      return
    end

    response = Balances::IndexService.new(group: group).call
    
    unless response[:success]
      @errors << "Unable to verify user's outstanding balance"
      return
    end

    balance = response[:balances][user.id] || 0

    unless balance.zero?
      @errors << "User has outstanding balances to settle"
    end
  end

  def validate_different_users
    return if admin.blank? || user.blank?

    @errors << "Admin cannot remove themselves" if admin.id == user.id
  end

  def remove_member
    @membership.update!(status: "inactive")
  end

end