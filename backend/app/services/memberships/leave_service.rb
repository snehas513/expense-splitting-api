class Memberships::LeaveService
  include GroupValidation
  attr_reader :group, :user

  def initialize(group:, user:)
    @group = group
    @user = user
    @errors = []
  end

  def call
    return { success: false, errors: ["Group is required"] } if group.blank?

    group.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
      
      leave_group
    end

    { success: true, membership: @membership }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_group
    validate_user
    validate_admin
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

  def validate_admin
    return if @membership.blank?

    return unless @membership.role == "admin"

    another_admin_exists = Membership.where(
          group_id: group.id,
          status: "active",
          role: "admin"
        ).where.not(id: @membership.id).exists?
        
    @errors << "Group must have at least one active admin" unless another_admin_exists
  end

  def leave_group
    @membership.update!(status: "inactive")
  end

end