class Expenses::CreateService
  attr_reader :group, :creator, :payer, :participants,
            :amount, :description, :expense_date, :note
  
  def initialize(group:, creator:, payer:, participants:, amount:, description:, expense_date:, note: nil)
    @group = group
    @creator = creator
    @payer = payer
    @participants = participants || []
    @amount = amount
    @description = description
    @expense_date = expense_date
    @note = note
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    
    Expense.transaction do
      create_expense
      create_participants
    end
    { success: true, expense: @expense }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private
  
  def validate
    validate_group

    user_ids = [creator&.id, payer&.id, *participants.compact.map(&:id)].compact.uniq
    @active_member_ids = group.present? ? active_member_ids(user_ids) : []

    validate_creator
    validate_participants
    validate_payer
    validate_amount_precision
  end

  def validate_group
    if group.blank?
      @errors << "Group is required"
    elsif !group.active?
      @errors << "Group must be active"
    end
  end

  def validate_active_user(type:, user:)
    @errors << "#{type} must have an active account and active membership in the group" unless user.active? &&
      @active_member_ids.include?(user.id)
  end

  def validate_creator
    if creator.blank?
      @errors << "Creator is required"
      return
    end

    validate_active_user(type: "Creator", user: creator)
  end

  def validate_payer
    if payer.blank?
      @errors << "Payer is required"
      return
    end

    validate_active_user(type: "Payer", user: payer)

    return if participants.any?(&:nil?)

    @errors << "Payer must be a participant" if participants.present? && participants.map(&:id).exclude?(payer.id)
  end

  def validate_participants
    if participants.blank?
      @errors << "Participants cannot be empty"
      return
    end

    if participants.any?(&:nil?)
      @errors << "Participants cannot contain nil values"
      return
    end

    @errors << "At least two participants are required" if participants.size < 2

    @errors << "Duplicate participants are not allowed" if participants.map(&:id).uniq.size != participants.size

    @errors << "Every participant must have an active account and active membership" unless participants.all? do |p|
      p.active? && @active_member_ids.include?(p.id)
    end
  end

  def validate_amount_precision
    if amount.blank?
      @errors << "Amount is required"
      return
    end

    begin
      value = BigDecimal(amount.to_s)
    rescue ArgumentError
      @errors << "Amount must be a valid number"
      return
    end

    @errors << "Amount must be greater than 0" unless value.positive?

    @errors << "Amount cannot have more than two decimal places" unless value == value.round(2)
  end

  def calculate_equal_shares
    total_paise = (BigDecimal(amount.to_s) * 100).to_i
    participant_count = participants.size

    base_share = total_paise / participant_count
    remainder = total_paise % participant_count

    @equal_shares = participants.each_with_index.map do |_, index|
      share_paise = base_share + (index < remainder ? 1 : 0)
      BigDecimal(share_paise.to_s) / 100
    end
  end

  def create_expense
    @expense = Expense.create!(
      group: group,
      payer: payer,
      creator: creator,
      amount: amount,
      description: description,
      status: "active",
      expense_date: expense_date,
      note: note
    )
  end

  def create_participants
    calculate_equal_shares

    participants.each_with_index do |participant, index|
      ExpenseParticipant.create!(
        expense: @expense, 
        user: participant, 
        share_amount: @equal_shares[index]
      )
    end
  end

  def active_member_ids(user_ids)
    Membership.where(
      user_id: user_ids,
      group_id: group.id,
      status: "active"
    ).pluck(:user_id)
  end

# group, creator, payer, participants, amount, description, expense_date, note = Group.last, User.find(2), User.find(3), [User.find(3), User.find(4)], 2000, "Test", Date.current, nil

# Expenses::CreateService.new(
# group: group,
# creator: creator,
# payer: payer,
# participants: participants,
# amount: amount,
# description: description,
# expense_date: expense_date,
# note: note
# ).call


end