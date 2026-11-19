require "rails_helper"

RSpec.describe Memberships::RemoveService do
  let(:group) { create(:group) }
  let(:admin) { create(:user) }
  let(:user) { create(:user) }

  let(:result) {
    described_class.new(
      group: group,
      admin: admin,
      user: user
    ).call
  }

  describe "#call" do
  
    context "when all attributes are valid" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user) }

      it "marks the user's membership as inactive" do
        expect(result[:success]).to be(true)
        expect(result[:membership].status).to eq("inactive")
        expect(result[:membership].role).to eq(user_membership.reload.role)
        expect(user_membership.status).to eq("inactive")
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

    context "when the admin is missing" do
      let(:admin) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Admin is required")
      end
    end

    context "when the admin is deactivated" do
      let(:admin) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Admin must have an active account")
      end
    end

    context "when the admin has inactive membership" do
      let!(:admin_membership) { create(:membership, :inactive, group: group, user: admin, role: "admin") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Admin is not an active admin member of the group")
      end
    end
    context "when the user is missing" do
      let(:user) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is required")
      end
    end

    context "when the user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User must have an active account")
      end
    end

    context "when there  user has inactive membership" do
      let!(:user_membership) { create(:membership, :inactive, group: group, user: user) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is not an active member of the group")
      end
    end

    context "when balance calculation failed" do
      let!(:user_membership) { create(:membership, group: group, user: user) }

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
      let!(:user_membership) { create(:membership, group: group, user: user) }
      let!(:participant_membership) { create(:membership, group: group, user: participant) }

      let(:expense) { create(:expense, group: group, payer: participant) }

      let!(:expense_participants) do 
        [ 
          create(:expense_participant,
            expense: expense,
            user: user,
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
        expect(user_membership.reload.status).to eq("active")
      end
    end

    context "when the admin tries to remove themselves" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let(:user) { admin }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Admin cannot remove themselves")
        expect(admin_membership.reload.status).to eq("active")
      end
    end
  end
end