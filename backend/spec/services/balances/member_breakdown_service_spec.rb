require "rails_helper"

RSpec.describe Balances::MemberBreakdownService do
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:member) { create(:user) }

  let(:result) {
    described_class.new(
      group: group,
      user: user,
      member: member
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      it "calculates outstanding_debt between user and member, also the amount they owe each other" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:user_owes_member].first[:share_amount]).to eq(BigDecimal("750.00"))
        expect(result[:breakdown][:member_owes_user].first[:share_amount]).to eq(BigDecimal("450.00"))
      end
    end

    context "when pending settlements from user to member" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      let!(:settlement) { 
          create(
            :settlement,
            group: group,
            sender: user,
            receiver: member,
            creator: user,
            settlement_amount: 200,
            status: "pending"
          )
        }

        let!(:existing_allocation) do
          create(
            :settlement_expense,
            settlement: settlement,
            expense: expense1,
            allocation_amount: 200
          )
        end

      it "reduces remaining amount" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:user_owes_member].first[:remaining_amount]).to eq(BigDecimal("550.00"))
        expect(result[:breakdown][:user_owes_member].first[:allocated_amount]).to eq(BigDecimal("200.00"))
        expect(result[:breakdown][:member_owes_user].first[:remaining_amount]).to eq(BigDecimal("450.00"))
      end
    end

    context "when confirmed settlements from user to member" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      let!(:settlement) { 
          create(
            :settlement,
            group: group,
            sender: user,
            receiver: member,
            creator: user,
            settlement_amount: 200,
            status: "confirmed"
          )
        }

        let!(:existing_allocation) do
          create(
            :settlement_expense,
            settlement: settlement,
            expense: expense1,
            allocation_amount: 200
          )
        end

      it "reduces remaining amount and outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("100.00"))
        expect(result[:breakdown][:user_owes_member].first[:remaining_amount]).to eq(BigDecimal("550.00"))
        expect(result[:breakdown][:user_owes_member].first[:allocated_amount]).to eq(BigDecimal("200.00"))
        expect(result[:breakdown][:member_owes_user].first[:remaining_amount]).to eq(BigDecimal("450.00"))
      end
    end

    context "when there are multiple pending settlements from user to member" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      let!(:settlement1) {
        create(
          :settlement,
          group: group,
          sender: user,
          receiver: member,
          creator: user,
          settlement_amount: 100,
          status: "pending"
        )
      }

      let!(:existing_allocation_for_settlement1) do
        create(
          :settlement_expense,
          settlement: settlement1,
          expense: expense1,
          allocation_amount: 100
        )
      end

      let!(:settlement2) {
        create(
          :settlement,
          group: group,
          sender: user,
          receiver: member,
          creator: user,
          settlement_amount: 150,
          status: "pending"
        )
      }

      let!(:existing_allocation_for_settlement2) do
        create(
          :settlement_expense,
          settlement: settlement2,
          expense: expense1,
          allocation_amount: 150
        )
      end

      it "reduces remaining amount" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:user_owes_member].first[:remaining_amount]).to eq(BigDecimal("500.00"))
        expect(result[:breakdown][:user_owes_member].first[:allocated_amount]).to eq(BigDecimal("250.00"))
        expect(result[:breakdown][:member_owes_user].first[:remaining_amount]).to eq(BigDecimal("450.00"))
      end
    end

    context "when there is pending settlement from member to user" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      let!(:settlement) { 
          create(
            :settlement,
            group: group,
            sender: member,
            receiver: user,
            creator: member,
            settlement_amount: 200,
            status: "pending"
          )
        }

        let!(:existing_allocation) do
          create(
            :settlement_expense,
            settlement: settlement,
            expense: expense2,
            allocation_amount: 200
          )
        end

      it "reduces remaining amount" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:user_owes_member].first[:remaining_amount]).to eq(BigDecimal("750.00"))
        expect(result[:breakdown][:member_owes_user].first[:allocated_amount]).to eq(BigDecimal("200.00"))
        expect(result[:breakdown][:member_owes_user].first[:remaining_amount]).to eq(BigDecimal("250.00"))
      end
    end

    context "when there is fully allocated pending settlements from user to member" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      let!(:settlement) { 
          create(
            :settlement,
            group: group,
            sender: user,
            receiver: member,
            creator: user,
            settlement_amount: 750,
            status: "pending"
          )
        }

        let!(:existing_allocation) do
          create(
            :settlement_expense,
            settlement: settlement,
            expense: expense1,
            allocation_amount: 750
          )
        end

      it "excludes fully allocated expenses from the breakdown" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:user_owes_member]).to be_empty
        expect(result[:breakdown][:member_owes_user].first[:remaining_amount]).to eq(BigDecimal("450.00"))
      end
    end

    context "when there is pending settlements from user to member, also from member to user" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      let!(:settlement1) { 
        create(
          :settlement,
          group: group,
          sender: user,
          receiver: member,
          creator: user,
          settlement_amount: 200,
          status: "pending"
        )
      }

      let!(:existing_allocation1) do
        create(
          :settlement_expense,
          settlement: settlement1,
          expense: expense1,
          allocation_amount: 200
        )
      end

      let!(:settlement2) { 
        create(
          :settlement,
          group: group,
          sender: member,
          receiver: user,
          creator: member,
          settlement_amount: 300,
          status: "pending"
        )
      }

      let!(:existing_allocation2) do
        create(
          :settlement_expense,
          settlement: settlement2,
          expense: expense2,
          allocation_amount: 300
        )
      end


      it "excludes fully allocated expenses from the breakdown" do
        expect(result[:success]).to be(true)
        expect(result[:breakdown][:outstanding_debt]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:user_owes_member].first[:allocated_amount]).to eq(BigDecimal("200.00"))
        expect(result[:breakdown][:user_owes_member].first[:remaining_amount]).to eq(BigDecimal("550.00"))
        expect(result[:breakdown][:member_owes_user].first[:allocated_amount]).to eq(BigDecimal("300.00"))
        expect(result[:breakdown][:member_owes_user].first[:remaining_amount]).to eq(BigDecimal("150.00"))
      end
    end

    context "when PairwiseService fails" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      before do
        allow_any_instance_of(Balances::PairwiseService)
          .to receive(:call)
          .and_return(success: false, errors: ["Balance calculation failed"])
      end

        
      it "returns the PairwiseService errors" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Balance calculation failed")
      end
    end

    context "when group is missing" do
      let(:group) { nil }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived) }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
      end
    end

    context "when user and member are the same user" do
      let(:result) {
        described_class.new(
          group: group,
          user: user,
          member: user
        ).call
      }

      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User and Member must be different users")
      end
    end

    context "when user is not an active group member" do
      before do
        user.update!(status: "deactivated")
      end

      let!(:memberships) do
        [member].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User must have an active account and active membership in the group")
      end
    end

    context "when member is not an active group member" do
      before do
        member.update!(status: "deactivated")
      end

      let!(:memberships) do
        [user].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Member must have an active account and active membership in the group")
      end
    end

    context "when member is missing" do
      let(:member) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Member is required")
      end
    end

    context "when user is missing" do
      let(:user) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is required")
      end
    end
    
    context "when user has no active group membership" do
      let!(:membership) do
        create(:membership, group: group, user: member)
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account and active membership in the group"
        )
      end
    end

    context "when member has no active group membership" do
      let!(:membership) do
        create(:membership, group: group, user: user)
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Member must have an active account and active membership in the group"
        )
      end
    end

    context "when both user and member have inactive group membership" do
      let!(:membership) do
        [member, user].map do |user|
          create(:membership, :inactive, group: group, user: user)
        end
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account and active membership in the group"
        )
        expect(result[:errors]).to include(
          "Member must have an active account and active membership in the group"
        )
      end
    end
  end
end