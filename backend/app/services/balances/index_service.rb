module Balances
  class IndexService
    attr_reader :group

    def initialize(group:)
      @group = group
      @errors = []
    end

    def call
      validate
      return { success: false, errors: @errors } unless @errors.empty?
      calculate_balances
    end

    def validate
      validate_group
    end

    def validate_group
      if group.blank?
        @errors << "Group is required"
      elsif !group.active?
        @errors << "Group must be active"
      end
    end

    def calculate_balances
      balances = {}
      active_member_ids = Membership.joins(:user)
        .where(
          group_id: group.id,
          status: "active",
          users: { status: "active" }
        )
        .distinct
        .pluck(:user_id) 
        .to_set

      active_member_ids.each do |id|
        balances[id] = BigDecimal("0")
      end

      group_expenses = group.expenses.active.includes(:expense_participants)
      group_expenses.each do |expense|
        payer_participation = expense.expense_participants.find do |p|
          p.user_id == expense.paid_by_id
        end

        unless payer_participation
          return {
            success: false,
            errors: ["Payer is not an expense participant for expense #{expense.id}"]
          }
        end

        total_shares = expense.expense_participants.sum(&:share_amount)

        unless total_shares == expense.amount
          return {
            success: false,
            errors: ["Participant shares do not match expense amount for expense #{expense.id}"]
          }
        end


        expense.expense_participants.each do |participant|
          unless active_member_ids.include?(participant.user_id)
            return {
              success: false,
              errors: ["Participant ID #{participant.user_id} is not an active group member for expense #{expense.id}"]
            }
          end

          if participant.user_id == expense.paid_by_id
            balances[participant.user_id] += expense.amount - participant.share_amount
          else
            balances[participant.user_id] -= participant.share_amount
          end
        end

      end
      
      unless balances.values.sum(BigDecimal("0")).zero?
        return {
          success: false,
          errors: ["The sum of group balances must be zero"]
        }
      end
      { success: true, balances: balances }
    end
    
  end
end