require 'rails_helper'

RSpec.describe SettlementExpense, type: :model do
  
  let(:group) { create(:group) }

  let(:participant_a) { create(:user) }
  let(:participant_b) { create(:user) }

  let!(:memberships) do
    [participant_a, participant_b].map do |user|
      create(:membership, group: group, user: user)
    end
  end

  let!(:expense) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1000) }

  let!(:expense_participant_for_expense) do
    [participant_a, participant_b].map do |user|
      create(:expense_participant,
        expense: expense,
        user: user,
        share_amount: 500
      )
    end
  end

  let!(:settlement) { 
    create(
      :settlement,
      :confirmed,
      group: group,
      sender: participant_b,
      receiver: participant_a,
      creator: participant_b,
      settlement_amount: 100
    )
  }
  context "when all attributes are valid" do
    it "is valid with valid attributes" do
      settlement_expense = build(
        :settlement_expense,
        settlement: settlement,
        expense: expense,
        allocation_amount: 50
      )

      expect(settlement_expense).to be_valid
    end
  end

  context "when allocation_amount is zero" do
    it "is invalid when allocation_amount is zero" do
      settlement_expense = build(
        :settlement_expense,
        settlement: settlement,
        expense: expense,
        allocation_amount: 0
      )

      expect(settlement_expense).not_to be_valid
      expect(settlement_expense.errors[:allocation_amount]).to be_present
    end
  end
end
