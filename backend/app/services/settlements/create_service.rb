class Settlements::CreateService
  include DateParser
  attr_reader :group, :sender, :receiver, :creator, :settlement_amount, :settlement_date, :note, :allocations
  
  def initialize(group:, sender:, receiver:, creator:, settlement_amount:, settlement_date:, allocations:, note: nil)
    @group = group
    @sender = sender
    @receiver = receiver
    @creator = creator
    @settlement_amount = settlement_amount
    @settlement_date = settlement_date
    @allocations = allocations || []
    @note = note
    @errors = []
  end

  def call
    return { success: false, errors: ["Group is required"] } if group.blank?

    group.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
     
      Settlement.transaction do
        create_settlement
        create_settlement_expenses
      end
        
        { success: true, settlement: @settlement }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors.full_messages }
    end
  end

  private

  def validate
    validate_group
    user_ids = [sender&.id, receiver&.id, creator&.id].compact.uniq
    @active_member_ids = group.present? ? active_member_ids(user_ids) : []

    validate_sender
    validate_receiver
    validate_different_users
    validate_creator
    validate_settlement_amount
    validate_settlement_date
    validate_allocations
    return unless @errors.empty?

    validate_total_allocation_amount
    validate_allocation_amount_against_expense
    validate_available_amount
  end

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def active_member_ids(user_ids)
    Membership.where(
      user_id: user_ids,
      group_id: group.id,
      status: "active"
    ).pluck(:user_id)
  end

  def validate_active_user(type:, user:)
    @errors << "#{type} must have an active account and active membership in the group" unless user.active? &&
      @active_member_ids.include?(user.id)
  end

  def validate_sender
    if sender.blank?
      @errors << "Sender is required"
      return
    end

    validate_active_user(type: "Sender", user: sender)
  end

  def validate_receiver
    if receiver.blank?
      @errors << "Receiver is required"
      return
    end

    validate_active_user(type: "Receiver", user: receiver)
  end

  def validate_different_users
    return if sender.blank? || receiver.blank?

    @errors << "Sender and receiver must be different users" if sender.id == receiver.id
  end

  def validate_creator
    if creator.blank?
      @errors << "Creator is required"
      return
    end

    validate_active_user(type: "Creator", user: creator)

    return if sender.blank? || receiver.blank?
    
    @errors << "Creator must be either the sender or receiver" if creator.id != sender.id && creator.id != receiver.id
  end

  def validate_settlement_amount
    if settlement_amount.blank?
      @errors << "Settlement Amount is required"
      return
    end

    begin
      value = BigDecimal(settlement_amount.to_s)
    rescue ArgumentError, TypeError
      @errors << "Settlement Amount must be a valid number"
      return
    end

    unless value.finite?
      @errors << "Settlement Amount must be a finite number"
      return
    end

    max_settlement_amount = BigDecimal("9999999999.99")

    if value > max_settlement_amount
      @errors << "Settlement Amount exceeds the maximum allowed value"
      return
    end

    unless value.positive? && value == value.round(2) 
      @errors << "Settlement Amount must be greater than 0" unless value.positive?
      @errors << "Settlement Amount cannot have more than two decimal places" unless value == value.round(2) 
      return
    end

    @settlement_amount = value
  end

  def validate_settlement_date
    if settlement_date.blank?
      @errors << "Settlement Date is missing"
      return
    end

    parsed_settlement_date = parse_date(settlement_date)

    if parsed_settlement_date.nil?
      @errors << "Settlement Date is invalid"
      return
    end
    @settlement_date = parsed_settlement_date
  end

  def validate_available_amount
    result = Balances::PairwiseService.new(group: group, sender: sender, receiver: receiver).call
    unless result[:success]
      @errors.concat(result[:errors])
      return
    end
    outstanding_debt = result[:outstanding_debt]

    pending_settlements = group.settlements.pending
      .where(sender: sender, receiver: receiver)
      .sum(:settlement_amount)

    available_amount = outstanding_debt - pending_settlements
    available_amount = [available_amount, BigDecimal("0")].max

    @errors << "Settlement amount exceeds the available amount" if settlement_amount > available_amount
  end

  def validate_allocations
    @validated_allocations = []

    unless allocations.is_a?(Array) && allocations.present?
      @errors << "Allocations must be a non-empty array"
      return
    end

    expense_ids = allocations.map { |a| a[:expense_id] if a.is_a?(Hash) }

    if expense_ids.compact.uniq.size != expense_ids.size
      @errors << "Duplicate expense allocations are not allowed"
      return
    end

    if allocations.any?(&:nil?)
      @errors << "Allocations cannot contain nil values"
      return
    end

    @group_expenses = group.expenses.active.index_by(&:id)
    allocations.each do |allocation|
      unless allocation.is_a?(Hash)
        @errors << "Each allocation must be an object"
        next
      end

      expense = @group_expenses[allocation[:expense_id]]
      unless expense
        @errors << "Allocation for expense ID #{allocation[:expense_id]} not found"
      end

      if allocation[:allocation_amount].blank?
        @errors << "Allocation amount is required"
        next
      end

      begin
        value = BigDecimal(allocation[:allocation_amount].to_s)
      rescue ArgumentError, TypeError
        @errors << "Allocation amount for expense ID #{allocation[:expense_id]} must be a valid number"
        next
      end

      unless value.finite?
        @errors << "Allocation amount for expense ID #{allocation[:expense_id]} must be a finite number"
        next
      end

      unless value.positive?
        @errors << "Allocation amount for expense ID #{allocation[:expense_id]} must be greater than 0"
        next
      end

      unless value == value.round(2) 
        @errors << "Allocation amount for expense ID #{allocation[:expense_id]} cannot have more than two decimal places"
        next 
      end
      @validated_allocations << {expense_id: allocation[:expense_id], allocation_amount: value}
    end
  end

  def validate_total_allocation_amount
    total = @validated_allocations.sum { |a| a[:allocation_amount] }
    @errors << "Total allocations must equal settlement amount" unless total == settlement_amount
  end

  def validate_allocation_amount_against_expense
    @validated_allocations.each do |allocation|
      expense = @group_expenses[allocation[:expense_id]]
      sender_share = expense.expense_participants.find_by(user_id: sender.id)&.share_amount

      unless expense.paid_by_id == receiver.id
        @errors << "Expense ID #{expense.id} was not paid by the receiver"
        next
      end

      unless sender_share
        @errors << "Sender is not a participant in expense ID #{expense.id}"
        next
      end

      already_allocated = expense.settlement_expenses.joins(:settlement)
        .where(settlements: { status: %w[pending confirmed], sender_id:  sender.id, receiver_id: receiver.id}).sum(:allocation_amount)

      remaining_amount = sender_share - already_allocated

      if allocation[:allocation_amount] > remaining_amount
        @errors << "Allocation amount for expense ID #{allocation[:expense_id]} exceeds remaining amount"
      end
    end
  end

  def create_settlement
    @settlement = group.settlements.create!(
      sender: sender,
      receiver: receiver,
      creator: creator,
      settlement_amount: settlement_amount,
      status: "pending",
      settlement_date: settlement_date,
      note: note,
      acted_by: nil
    )
  end

  def create_settlement_expenses
    @settlement.settlement_expenses.create!(@validated_allocations)
  end
end