require "rails_helper"

RSpec.describe Balances::IndexService do
  let(:group) { create(:group) }

  let(:result) {
    described_class.new(
      group: group
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      let!(:expenses) do
        create_list(:expense, 25, group: group).each do |expense|
          payer = expense.payer
          participant = create(:user)
          
          create(:membership,
            group: group,
            user: participant,
            status: "active"
          )

          create(:expense_participant,
            expense: expense,
            user: payer,
            share_amount: 600
          )

          create(:expense_participant,
            expense: expense,
            user: participant,
            share_amount: 600
          )
        end
      end
      
      it "calculates balances for active group members" do
        expect(result[:success]).to be(true)
        total_balance = result[:balances].values.sum
        expect(total_balance).to eq(0)
        expect(result[:balances].keys).to match_array(
          Membership.where(group: group, status: "active").pluck(:user_id)
        )
      end
    end

    context "when multiple expenses have different payers" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: participant_b, payer: participant_b, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 300
          )
        end
      end
      
      it "calculates balances for active group members" do
        expect(result[:success]).to be(true)
        total_balance = result[:balances].values.sum
        expect(total_balance).to eq(0)
        expect(result[:balances].keys).to match_array(
          Membership.where(group: group, status: "active").pluck(:user_id)
        )
        expect(result[:balances][participant_a.id]).to eq(BigDecimal("700.00"))
        expect(result[:balances][participant_b.id]).to eq(BigDecimal("100.00"))
        expect(result[:balances][participant_c.id]).to eq(BigDecimal("-800.00"))

      end
    end

    context "when there is a member with zero balance" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }
      let(:participant_d) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_b, participant_c, participant_d].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: participant_b, payer: participant_b, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 300
          )
        end
      end
      
      it "includes active members with zero balance" do
        expect(result[:success]).to be(true)
        total_balance = result[:balances].values.sum
        expect(total_balance).to eq(0)
        expect(result[:balances].keys).to match_array(
          Membership.where(group: group, status: "active").pluck(:user_id)
        )
        expect(result[:balances][participant_a.id]).to eq(BigDecimal("700.00"))
        expect(result[:balances][participant_b.id]).to eq(BigDecimal("100.00"))
        expect(result[:balances][participant_c.id]).to eq(BigDecimal("-800.00"))
        expect(result[:balances][participant_d.id]).to eq(BigDecimal("0.00"))

      end
    end

    context "when deleted expense is excluded from the balance calculation" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }
      let(:participant_d) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_b, participant_c, participant_d].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: participant_b, payer: participant_b, amount: 900, status: "deleted") }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 300
          )
        end
      end
      
      it "excludes deleted expenses from balance calculation" do
        expect(result[:success]).to be(true)
        total_balance = result[:balances].values.sum
        expect(total_balance).to eq(0)
        expect(result[:balances].keys).to match_array(
          Membership.where(group: group, status: "active").pluck(:user_id)
        )
        expect(result[:balances][participant_a.id]).to eq(BigDecimal("1000.00"))
        expect(result[:balances][participant_b.id]).to eq(BigDecimal("-500.00"))
        expect(result[:balances][participant_c.id]).to eq(BigDecimal("-500.00"))
        expect(result[:balances][participant_d.id]).to eq(BigDecimal("0.00"))
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived) }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
      end
    end

    context "when payer is not an expense participant for an expense" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }
      let(:participant_d) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_b, participant_c, participant_d].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1500) }

      let!(:expense_participant_for_expense1) do
        [participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Payer is not an expense participant for expense #{expense1.id}")
      end
    end

    context "when an expense participant is not an active member of the group" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }
      let(:participant_d) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_c, participant_d].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1000) }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Participant ID #{participant_b.id} is not an active group member for expense #{expense1.id}")
      end
    end

    context "when the group membership of an expense participant is inactive" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }
      let(:participant_d) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_c, participant_d].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:participant_b_membership) do
        create(:membership, :inactive ,group: group, user: participant_b) 
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1000) }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Participant ID #{participant_b.id} is not an active group member for expense #{expense1.id}")
      end
    end

    context "when an user account is deactivated" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user, :deactivated) }
      let(:participant_c) { create(:user) }
      let(:participant_d) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_b, participant_c, participant_d].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1000) }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Participant ID #{participant_b.id} is not an active group member for expense #{expense1.id}")
      end
    end

    context "when group is missing" do
      let(:group) { nil }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when participant shares do not match expense amount for an expense" do
      let(:participant_a) { create(:user) }
      let(:participant_b) { create(:user) }
      let(:participant_c) { create(:user) }

      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1000) }

      let!(:expense_participant_for_expense1) do
        [participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end

      let!(:expense_participant_a_for_expense1) do
        create(:expense_participant,
          expense: expense1,
          user: participant_a,
          share_amount: 600
        )
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Participant shares do not match expense amount for expense #{expense1.id}")
      end
    end

  end
end