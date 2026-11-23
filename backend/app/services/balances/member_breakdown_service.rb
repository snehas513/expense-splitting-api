class Balances::MemberBreakdownService
  include GroupValidation
  attr_reader :group, :user, :member

  def initialize(group:, user:, member:)
    @group = group
    @user = user
    @member = member
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?

    breakdown = build_breakdown
    return { success: false, errors: @errors } unless @errors.empty?

    { success: true, breakdown: breakdown }
  end

  private

  def validate
    validate_group

    user_ids = [user&.id, member&.id].compact.uniq
    @active_member_ids = group.present? ? active_member_ids(user_ids) : []

    validate_active_user(type: "User", user: user)
    validate_active_user(type: "Member", user: member)
    validate_different_users
  end

  def active_member_ids(user_ids)
    Membership.where(
      user_id: user_ids,
      group_id: group.id,
      status: "active"
    ).pluck(:user_id)
  end

  def validate_active_user(type:, user:)
    if user.blank?
      @errors << "#{type} is required"
      return
    end

    @errors << "#{type} must have an active account and active membership in the group" unless user.active? &&
      @active_member_ids.include?(user.id)
  end

  def validate_different_users
    return if user.blank? || member.blank?

    @errors << "User and Member must be different users" if user.id == member.id
  end

  def calculate_remaining_amounts(user:, member:)
    group_expenses = group.expenses.active

    expenses = group_expenses
      .joins(:expense_participants)
      .where(
        paid_by_id: member.id,
        expense_participants: { user_id: user.id }
      )

    expenses_by_id = expenses.index_by(&:id)

    user_shares = expenses
      .group('expenses.id')
      .sum('expense_participants.share_amount')

    allocated_amounts = SettlementExpense
      .joins(:settlement)
      .where(settlements: {sender_id: user.id, receiver_id: member.id, status: %w[pending confirmed]}, expense_id: expenses.select(:id))
      .group(:expense_id)
      .sum(:allocation_amount)

    remaining_amounts = user_shares.each_with_object({}) do |(expense_id, share), result|
      allocated = allocated_amounts.fetch(expense_id, BigDecimal("0"))
      result[expense_id] = share - allocated
    end

    result = remaining_amounts.each_with_object([]) do |(expense_id, remaining), array|
      next if remaining <= 0

      expense = expenses_by_id[expense_id]
      share = user_shares[expense_id]
      allocated = allocated_amounts.fetch(expense_id, BigDecimal("0"))

      array << {
        expense: expense,
        share_amount: share,
        allocated_amount: allocated,
        remaining_amount: remaining
      }
    end
    result
  end

  def build_breakdown
    result = Balances::PairwiseService.new(group: group, sender: user, receiver: member).call
    unless result[:success]
      @errors.concat(result[:errors])
      return
    end

    outstanding_debt = result[:outstanding_debt]

    # Expenses paid by member, where user participated
    user_owes_member = calculate_remaining_amounts(user: user, member: member)

    # Expenses paid by user, where member participated
    member_owes_user = calculate_remaining_amounts(user: member, member: user)

    {
      outstanding_debt: outstanding_debt,
      user_owes_member: user_owes_member,
      member_owes_user: member_owes_user
    }
  end
    
end

