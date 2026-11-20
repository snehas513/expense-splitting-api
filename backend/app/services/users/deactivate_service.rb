class Users::DeactivateService
  attr_reader :user

  def initialize(user:)
    @user = user
    @errors = []
  end

  def call
    return { success: false, errors: ["User is required"] } if user.blank?

    user.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
    
      deactivate_user
    end
    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_user
    validate_net_balance if @errors.empty?
    admin_check if @errors.empty?
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
  end

  def validate_net_balance
    total_net_balance = 0
    @user_groups = Group.joins(:memberships)
                    .where(
                      memberships: { user_id: user.id, status: "active" },
                      status: "active"
                    )

    @user_groups.each do |group|
      response = Balances::IndexService.new(group: group).call

      unless response[:success]
        @errors << "Unable to verify user's outstanding balance for group ID #{group.id}"
        next
      end

      balance = response[:balances][user.id] || 0
      total_net_balance += balance
    end

    unless total_net_balance.zero?
      @errors << "User has outstanding balances to settle"
    end
  end

  def admin_check
    @user_groups.each do |group|
      another_admin_exists = Membership.where(
            group_id: group.id,
            status: "active",
            role: "admin"
          ).where.not(user_id: user.id).exists?
          
      unless another_admin_exists
        @errors << "Group must have at least one active admin, group ID #{group.id}"
        next
      end
    end
  end

  def deactivate_user
    user.update!(status: "deactivated")

    user.memberships.where(status: "active").find_each do |membership|
      membership.update!(status: "inactive")
    end
  end


end