class Settlements::CreateService
  include DateParser
  attr_reader :group, :sender, :receiver, :creator, :settlement_amount, :settlement_date, :note
  
  def initialize(group:, sender:, receiver:, creator:, settlement_amount:, settlement_date:, note: nil)
    @group = group
    @sender = sender
    @receiver = receiver
    @creator = creator
    @settlement_amount = settlement_amount
    @settlement_date = settlement_date
    @note = note
    @errors = []
  end

  def call
    return { success: false, errors: ["Group is required"] } if group.blank?

    group.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?
     
      begin
        create_settlement
        { success: true, settlement: @settlement }
      rescue ActiveRecord::RecordInvalid => e
        { success: false, errors: e.record.errors.full_messages }
      end
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
    return unless @errors.empty?

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
    rescue ArgumentError
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
end