class Memberships::UpdateService
  include GroupValidation
  attr_reader :group, :admin, :user, :role

  def initialize(group:, admin:, user:, role:)
    @group = group
    @admin = admin
    @user = user
    @role = role
    @errors = []
  end

  def call
    return { success: false, errors: ["Group is required"] } if group.blank?

    group.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
      
      update_membership
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
    validate_role
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
    end
  end

  def validate_different_users
    return if admin.blank? || user.blank?

    @errors << "Admin cannot change their own role" if admin.id == user.id
  end

  def validate_role
    unless Membership::ROLE_TYPES.include?(role)
      @errors << "Role must be one of: #{Membership::ROLE_TYPES.join(', ')}"
      return 
    end

    return if @membership.blank?

    if @membership.role == role
      @errors << "User already has this role"
    end
  end

  def update_membership
    @membership.update!(role: role)
  end

end