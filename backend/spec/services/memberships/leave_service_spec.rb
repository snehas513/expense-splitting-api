require "rails_helper"

RSpec.describe Memberships::LeaveService do
  let(:group) { create(:group) }
  let(:user1) { create(:user) }

  let(:result) {
    described_class.new(
      group: group,
      user: user1
    ).call
  }

  describe "#call" do
  
    context "when all attributes are valid" do
      let!(:memberships) do
        admin_members = create_list(:membership, 10, group: group, role: "admin")
        default_members = create_list(:membership, 5, group: group, role: "member")
        inactive_default_members = create_list(:membership, 2, :inactive, group: group, role: "member")

        admin_members + default_members + inactive_default_members
      end
      let!(:user1_membership) { create(:membership, group: group, user: user1) }

      it "marks the user's membership as inactive" do
        expect(result[:success]).to be(true)
        expect(result[:membership].status).to eq("inactive")
        expect(result[:membership].role).to eq("member")
      end
    end

    context "when the group has more than one active admin" do
      let!(:memberships) do
        admin_members = create_list(:membership, 10, group: group, role: "admin")
        default_members = create_list(:membership, 5, group: group, role: "member")
        inactive_default_members = create_list(:membership, 2, :inactive, group: group, role: "member")

        admin_members + default_members + inactive_default_members
      end
      let!(:user1_membership) { create(:membership, group: group, user: user1, role: "admin") }

      it "marks the user's membership as inactive" do
        expect(result[:success]).to be(true)
        expect(result[:membership].status).to eq("inactive")
        expect(result[:membership].role).to eq("admin")
      end
    end

    context "when the group is missing" do
      let(:group) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when the group is archived" do
      let(:group) { create(:group, :archived) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
      end
    end

    context "when the user is missing" do
      let(:user1) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is required")
      end
    end

    context "when there  user is deactivated" do
      let(:user1) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User must have an active account")
      end
    end

    context "when there  user has inactive membership" do
      let!(:user1_membership) { create(:membership, :inactive, group: group, user: user1) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is not an active member of the group")
      end
    end

    context "when balance calculation failed" do
      let!(:user1_membership) { create(:membership, group: group, user: user1) }

      before do
        allow_any_instance_of(Balances::IndexService)
          .to receive(:call)
          .and_return(success: false, errors: ["Balance calculation failed"])
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Unable to verify user's outstanding balance"
        )
      end
    end

    context "when the user has outstanding balances to settle" do
      let(:participant) { create(:user) }
      let!(:user1_membership) { create(:membership, group: group, user: user1) }
      let!(:participant_membership) { create(:membership, group: group, user: participant) }

      let(:expense) { create(:expense, group: group, payer: user1) }

      let!(:expense_participants) do 
        [ 
          create(:expense_participant,
            expense: expense,
            user: user1,
            share_amount: 600
          ),

          create(:expense_participant,
            expense: expense,
            user: participant,
            share_amount: 600
          )
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User has outstanding balances to settle"
        )
        expect(user1_membership.reload.status).to eq("active")
      end
    end

    context "when group must have at least one active admin" do
      let!(:memberships) do
        default_members = create_list(:membership, 5, group: group, role: "member")
        inactive_default_members = create_list(:membership, 2, :inactive, group: group, role: "member")

        default_members + inactive_default_members
      end
      let!(:user1_membership) { create(:membership, group: group, user: user1, role: "admin") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group must have at least one active admin"
        )
        expect(user1_membership.reload.status).to eq("active")
      end
    end
  end
end