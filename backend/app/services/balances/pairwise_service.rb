module Balances
  class PairwiseService
    include GroupValidation
    attr_reader :group, :sender, :receiver

    def initialize(group:, sender:, receiver:)
      @group = group
      @sender = sender
      @receiver = receiver
      @errors = []
    end

    def call
      validate
      return { success: false, errors: @errors } unless @errors.empty?
      calculate_outstanding_debt
      { success: true, outstanding_debt: @outstanding_debt }
    end

    private

    def validate
      validate_group

      user_ids = [sender&.id, receiver&.id].compact.uniq
      @active_member_ids = group.present? ? active_member_ids(user_ids) : []

      validate_sender
      validate_receiver
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

    def calculate_outstanding_debt
      group_expenses = group.expenses.active
      group_settlements = group.settlements.confirmed
      receiver_share_amount = group_expenses.where(payer: sender).joins(:expense_participants)
        .where(expense_participants: {user_id: receiver.id})
        .sum("expense_participants.share_amount")

      sender_share_amount = group_expenses.where(payer: receiver).joins(:expense_participants)
        .where(expense_participants: {user_id: sender.id})
        .sum("expense_participants.share_amount")

      confirmed_settlements_from_sender = group_settlements.where(sender: sender, receiver: receiver).sum(:settlement_amount)
      confirmed_settlements_from_receiver = group_settlements.where(sender: receiver, receiver: sender).sum(:settlement_amount)

      @outstanding_debt = sender_share_amount - receiver_share_amount - confirmed_settlements_from_sender + confirmed_settlements_from_receiver
      @outstanding_debt = @outstanding_debt < 0 ? BigDecimal("0.00") : @outstanding_debt
    end

    


  end
end

# group = Group.first
# receiver = Group.first.users.second
# sender = Group.first.users.first

# Balances::PairwiseService.new(group: group, sender: sender, receiver: receiver).call