require "rails_helper"

RSpec.describe Expenses::CreateService do
  let(:group) { create(:group) }
  let(:creator) { create(:user) }
  let(:payer) { create(:user) }
  let(:participant1) { create(:user) }
  let(:participant2) { create(:user) }

  let(:participants) { [payer, participant1, participant2] }

  let(:amount) { 1000 }
  let(:description) { "Dinner" }
  let(:expense_date) { Date.current }
  let(:note) { "Team dinner" }

  let(:result) {
    described_class.new(
      group: group,
      creator: creator,
      payer: payer,
      participants: participants,
      amount: amount,
      description: description,
      expense_date: expense_date,
      note: note
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "creates an expense with three participants successfully" do
        expect(result[:success]).to be(true)
        expect(result[:expense]).to be_persisted
        expect(result[:expense].expense_participants.count).to eq(3)
        
        shares = result[:expense].expense_participants.pluck(:share_amount)
        expect(shares.sum).to eq(BigDecimal(amount.to_s))
      end
    end

    context "when group is missing" do
      let(:group) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when creator is missing" do
      let(:creator) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Creator is required")
      end
    end

    context "when payer is missing" do
      let(:payer) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Payer is required")
      end
    end

    context "when participants contain nil" do
      let(:participants) { [payer, nil] }

      it "returns a validation error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Participants cannot contain nil values")
      end
    end

    context "when fewer than two participants are provided" do
      let(:participants) { [payer] }

      it "returns a validation error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("At least two participants are required")
      end
    end

    context "when payer is not a participant" do
      let(:participants) { [participant1, participant2] }

      it "returns a validation error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Payer must be a participant")
      end
    end

    context "when participants contain duplicates" do
      let(:participants) { [participant1, participant1] }

      it "returns a validation error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Duplicate participants are not allowed")
      end
    end

    context "when participants is not an array" do
      let(:participants) { "invalid" }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Participants must be an array")
      end
    end

    context "when the amount cannot be divided equally among participants" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { 100 }

      it "distributes the remainder while keeping the total equal to the expense amount" do
        expect(result[:success]).to be(true)
        shares = result[:expense].expense_participants.order(:id).pluck(:share_amount)

        expect(shares).to eq([
          BigDecimal("33.34"),
          BigDecimal("33.33"),
          BigDecimal("33.33")
        ])

        expect(shares.sum).to eq(BigDecimal("100.00"))
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
      end
    end 

    context "when creator is deactivated" do
      let(:creator) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Creator must have an active account and active membership in the group")
      end
    end

    context "when payer is deactivated" do
      let(:payer) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Payer must have an active account and active membership in the group")
      end
    end

    context "when group is archived and payer is deactivated" do
      let(:group) { create(:group, :archived) }
      let(:payer) { create(:user, :deactivated) }

      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
        expect(result[:errors]).to include("Payer must have an active account and active membership in the group")
      end
    end

    context "when group is archived and creator is deactivated" do
      let(:group) { create(:group, :archived) }
      let(:creator) { create(:user, :deactivated) }

      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
        expect(result[:errors]).to include("Creator must have an active account and active membership in the group")
      end
    end

    context "when creator has an inactive membership" do
      let!(:memberships) do
        [
          create(:membership, :inactive, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, group: group, user: participant1),
          create(:membership, group: group, user: participant2)
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Creator must have an active account and active membership in the group"
        )
      end
    end

    context "when payer has an inactive membership" do
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, :inactive, group: group, user: payer),
          create(:membership, group: group, user: participant1),
          create(:membership, group: group, user: participant2)
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Payer must have an active account and active membership in the group"
        )
      end
    end

    context "when participant has an inactive membership" do
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, :inactive, group: group, user: participant1),
          create(:membership, group: group, user: participant2)
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Every participant must have an active account and active membership"
        )
      end
    end

    context "when a participant's account is deactivated but their group membership is active" do
      let(:participant1) { create(:user, :deactivated) }

      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, group: group, user: participant1),
          create(:membership, group: group, user: participant2)
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Every participant must have an active account and active membership"
        )
      end
    end

    context "when participant is empty" do
      let(:participants) { [] }
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer)
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Participants cannot be empty"
        )
      end
    end

    context "when participant is nil" do
      let(:participants) { nil }
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer)
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Participants cannot be empty"
        )
      end
    end

    context "when amount is missing" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { nil }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount is required"
        )
      end
    end
    
    context "when amount is zero" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { 0 }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount must be greater than 0"
        )
      end
    end

    context "when amount is negative" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { -100 }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount must be greater than 0"
        )
      end
    end

    context "when amount is invalid" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { "abc" }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount must be a valid number"
        )
      end
    end
    
    context "when amount is more than two decimal places" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { 1000.896 }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount cannot have more than two decimal places"
        )
      end
    end

    context "when amount is infinite" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { Float::INFINITY }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount must be a finite number"
        )
      end
    end

    context "when amount is infinite" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { Float::NAN }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount must be a finite number"
        )
      end
    end

    context "when amount exceeds maximum allowed value" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { "19999999999.99" }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Amount exceeds the maximum allowed value"
        )
      end
    end

    context "when amount is the maximum valid amount" do
      let!(:memberships) do
        [creator, payer, participant1, participant2].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let(:amount) { "9999999999.99" }
      
      it "returns an error" do
        expect(result[:success]).to be(true)
        expect(result[:expense].amount).to eq(BigDecimal("9999999999.99"))
      end
    end

    context "when creating an expense participant fails" do
      before do
        allow(ExpenseParticipant)
          .to receive(:create!)
          .and_raise(ActiveRecord::RecordInvalid.new(ExpenseParticipant.new))
      end

      it "rolls back the expense creation" do
        expect {
          result
        }.not_to change(Expense, :count)
        expect(result[:success]).to be(false)
        expect(ExpenseParticipant.count).to eq(0)
      end
    end

  end
end