require "rails_helper"

RSpec.describe Settlements::CreateService do
  let(:group) { create(:group) }

  let(:participant_a) { create(:user) }
  let(:participant_b) { create(:user) }
  let(:participant_c) { create(:user) }

  let(:sender) { participant_c }
  let(:creator) { participant_c }
  let(:receiver) { participant_a }

  let(:settlement_amount) { 100 }
  let(:settlement_date) { Date.current }
  let(:note) { "Settled ₹#{settlement_amount}" }

  let(:result) {
    described_class.new(
      group: group,
      sender: sender,
      receiver: receiver,
      creator: creator,
      settlement_amount: settlement_amount,
      settlement_date: settlement_date,
      note: note
    ).call
  }

  describe "#call" do
    describe "when the group has expenses" do

      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: participant_c, payer: participant_c, amount: 900) }

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

      context "when all attributes are valid" do
        
        it "creates a settlement successfully" do
          expect(result[:success]).to be(true)
          expect(result[:settlement]).to be_persisted
          expect(result[:settlement].settlement_amount).to eq(BigDecimal(settlement_amount.to_s))
          expect(result[:settlement].status).to eq("pending")
          expect(result[:settlement].sender).to eq(sender)
          expect(result[:settlement].receiver).to eq(receiver)
          expect(result[:settlement].creator).to eq(creator)
          expect(result[:settlement].acted_by).to be_nil
          expect(result[:settlement].settlement_date).to eq(settlement_date)
          expect(result[:settlement].note).to eq(note)
        end
      end

      context "when the settlement amount exceeds the outstanding debt" do
        let(:settlement_amount) { 300 }

        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement amount exceeds the available amount"
          )
        end
      end

      context "when pending settlements reducing the available amount" do
        let(:settlement_amount) { 100 }
        let!(:settlement) { 
          create(
            :settlement,
            group: group,
            sender: participant_c,
            receiver: participant_a,
            creator: participant_c,
            settlement_amount: 150
          )
        }

        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement amount exceeds the available amount"
          )
        end
      end

      context "when a pending settlement from the receiver to the sender should not reduce the sender-to-receiver available amount" do
        let(:settlement_amount) { 100 }
        let!(:settlement) { 
          create(
            :settlement,
            group: group,
            sender: participant_a,
            receiver: participant_c,
            creator: participant_a,
            settlement_amount: 150
          )
        }

        it "creates a settlement" do
          expect(result[:success]).to be(true)
          expect(result[:settlement]).to be_persisted
          expect(result[:settlement].settlement_amount).to eq(BigDecimal(settlement_amount.to_s))
          expect(result[:settlement].status).to eq("pending")
        end
      end

      context "when confirmed settlements reducing the available amount" do
        let(:settlement_amount) { 50 }
        let!(:settlement) { 
          create(
            :settlement,
            :confirmed,
            group: group,
            sender: participant_c,
            receiver: participant_a,
            creator: participant_c,
            settlement_amount: 150
          )
        }

        it "creates a settlement" do
          expect(result[:success]).to be(true)
          expect(result[:settlement]).to be_persisted
          expect(result[:settlement].settlement_amount).to eq(BigDecimal(settlement_amount.to_s))
          expect(result[:settlement].status).to eq("pending")
        end
      end

      context "when an existing confirmed settlement from receiver → sender should increase the outstanding debt sender owes receiver" do
        let(:settlement_amount) { 300 }
        let!(:settlement) { 
          create(
            :settlement,
            :confirmed,
            group: group,
            sender: participant_a,
            receiver: participant_c,
            creator: participant_a,
            settlement_amount: 100
          )
        }

        it "creates a settlement" do
          expect(result[:success]).to be(true)
          expect(result[:settlement]).to be_persisted
          expect(result[:settlement].settlement_amount).to eq(BigDecimal(settlement_amount.to_s))
          expect(result[:settlement].status).to eq("pending")
        end
      end

      context "when confirmed settlements have completely cleared the outstanding debt" do
        let(:settlement_amount) { 1 }
        let!(:settlement) { 
          create(
            :settlement,
            :confirmed,
            group: group,
            sender: participant_c,
            receiver: participant_a,
            creator: participant_c,
            settlement_amount: 200
          )
        }

        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement amount exceeds the available amount"
          )
        end
      end

      context "when the settlement amount equals the available amount" do
        let(:settlement_amount) { 200 }

        it "creates a settlement" do
          expect(result[:success]).to be(true)
          expect(result[:settlement]).to be_persisted
          expect(result[:settlement].settlement_amount).to eq(BigDecimal(settlement_amount.to_s))
          expect(result[:settlement].status).to eq("pending")
        end
      end

      context "when multiple pending settlements leave an exact available amount" do
        let(:settlement_amount) { 50 }
        let!(:settlements) do
          create_list(
            :settlement,
            2,
            group: group,
            sender: participant_c,
            receiver: participant_a,
            creator: participant_c,
            settlement_amount: 75
          )
        end

        it "creates a settlement" do
          expect(result[:success]).to be(true)
          expect(result[:settlement]).to be_persisted
          expect(result[:settlement].settlement_amount).to eq(BigDecimal(settlement_amount.to_s))
          expect(result[:settlement].status).to eq("pending")
        end
      end

    end

    describe "validations" do
      context "when group is missing" do
        let(:group) { nil }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Group is required"
          )
        end
      end

      context "when group is archived" do
        let(:group) { create(:group, :archived) }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Group must be active"
          )
        end
      end

      context "when sender is missing" do
        let(:sender) { nil }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Sender is required"
          )
        end
      end

      context "when sender is deactivated" do
        let(:sender) { create(:user, :deactivated) }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Sender must have an active account and active membership in the group"
          )
        end
      end

      context "when sender has inactive group membership" do
        let!(:memberships) do
          [
            create(:membership, :inactive, group: group, user: sender),
            create(:membership, group: group, user: receiver)
          ]
        end
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Sender must have an active account and active membership in the group"
          )
        end
      end

      context "when receiver is missing" do
        let(:receiver) { nil }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Receiver is required"
          )
        end
      end

      context "when receiver is deactivated" do
        let(:receiver) { create(:user, :deactivated) }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Receiver must have an active account and active membership in the group"
          )
        end
      end

      context "when receiver has inactive group membership" do
        let!(:memberships) do
          [
            create(:membership, group: group, user: sender),
            create(:membership, :inactive, group: group, user: receiver)
          ]
        end
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Receiver must have an active account and active membership in the group"
          )
        end
      end

      context "when there is no outstanding debt" do
        # Create active memberships, but no expenses.
        let!(:memberships) do
          [participant_a, participant_b, participant_c].map do |user|
            create(:membership, group: group, user: user)
          end
        end
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement amount exceeds the available amount"
          )
        end
      end

      context "when sender and receiver are the same user" do
        let!(:memberships) do
          [participant_a, participant_b, participant_c].map do |user|
            create(:membership, group: group, user: user)
          end
        end

        let(:result) {
          described_class.new(
            group: group,
            sender: sender,
            receiver: sender,
            creator: creator,
            settlement_amount: settlement_amount,
            settlement_date: settlement_date,
            note: note
          ).call
        }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Sender and receiver must be different users"
          )
        end
      end

      context "when creator is neither sender nor receiver" do
        let!(:memberships) do
          [participant_a, participant_b, participant_c].map do |user|
            create(:membership, group: group, user: user)
          end
        end

        let(:creator) { participant_b }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Creator must be either the sender or receiver"
          )
        end
      end

      context "when creator is deactivated and has inactive membership in the group" do
        let(:creator) { create(:user, :deactivated) }
        let!(:memberships) do
          [
            create(:membership, group: group, user: sender),
            create(:membership, :inactive, group: group, user: creator),
            create(:membership, group: group, user: receiver)
          ]
        end
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Creator must have an active account and active membership in the group"
          )
        end
      end

      context "when settlement amount is zero" do
        let(:settlement_amount) { 0 }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement Amount must be greater than 0"
          )
        end
      end

      context "when settlement amount is negative" do
        let(:settlement_amount) { -90 }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement Amount must be greater than 0"
          )
        end
      end

      context "when settlement amount has more than two decimal places" do
        let(:settlement_amount) { 100.234 }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement Amount cannot have more than two decimal places"
          )
        end
      end

      context "when settlement date is invalid" do
        let(:settlement_date) { "invalid-date" }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement Date is invalid"
          )
        end
      end

      context "when settlement date is missing" do
        let(:settlement_date) { nil }
        
        it "does not create a settlement" do
          expect(result[:success]).to be(false)
          expect {
            result
          }.not_to change(Settlement, :count)
          expect(result[:errors]).to include(
            "Settlement Date is missing"
          )
        end
      end
    end
  end
end