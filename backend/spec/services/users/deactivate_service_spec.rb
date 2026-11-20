require "rails_helper"

RSpec.describe Users::DeactivateService do
  let(:user) { create(:user) }
  let(:payer) { create(:user) }
  let(:group1) { create(:group) }
  let(:group2) { create(:group) }

  let(:result) {
    described_class.new(
      user: user
    ).call
  }

  describe "#call" do

    context "when all attributes are valid" do
      let!(:memberships) do
        [
          create(:membership, group: group1, user: user, role: "member"),
          create(:membership, group: group1, user: payer, role: "admin"),
          create(:membership, group: group2, user: user, role: "member"),
          create(:membership, group: group2, user: payer, role: "admin")
        ]
      end

      it "deactivate user  and its active memberships" do
        expect(result[:success]).to be(true)
        user.reload
        expect(user.status).to eq("deactivated")
        expect(user.memberships.pluck(:status).uniq).to eq(["inactive"])
      end
    end

    context "when user is missing" do
      let(:user) { nil }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is required"
        )
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account"
        )
      end
    end

    context "when user has outstanding balances to settle" do
      let!(:memberships) do
        [
          create(:membership, group: group1, user: user, role: "member"),
          create(:membership, group: group1, user: payer, role: "admin"),
          create(:membership, group: group2, user: user, role: "member"),
          create(:membership, group: group2, user: payer, role: "admin")
        ]
      end

      let!(:expense) { create(:expense, group: group1, creator: payer, payer: payer, amount: 900) }

      let!(:expense_participant_for_expense) do
        [payer, user].map do |participant|
          create(:expense_participant,
            expense: expense,
            user: participant,
            share_amount: 450
          )
        end
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User has outstanding balances to settle"
        )
        expect(user.status).to eq("active")
        expect(user.memberships.pluck(:status).uniq).to eq(["active"])
      end
    end

    context "when user is the only active admin of any active group" do
      let!(:memberships) do
        [
          create(:membership, group: group1, user: user, role: "member"),
          create(:membership, group: group1, user: payer, role: "admin"),
          create(:membership, group: group2, user: user, role: "admin")
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group must have at least one active admin, group ID #{group2.id}"
        )
        expect(user.status).to eq("active")
        expect(user.memberships.pluck(:status).uniq).to eq(["active"])
      end
    end

    context "when net balance calculation failed" do
      let!(:memberships) do
        [
          create(:membership, group: group1, user: user, role: "member"),
          create(:membership, group: group1, user: payer, role: "admin")
        ]
      end

      before do
        allow_any_instance_of(Balances::IndexService)
          .to receive(:call)
          .and_return(success: false, errors: ["Balance calculation failed"])
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Unable to verify user's outstanding balance for group ID #{group1.id}"
        )
        expect(user.status).to eq("active")
      end
    end

    context "when making a membership inactive fails" do
      let!(:memberships) do
        [
          create(:membership, group: group1, user: user, role: "member"),
          create(:membership, group: group1, user: payer, role: "admin"),
          create(:membership, group: group2, user: user, role: "member"),
          create(:membership, group: group2, user: payer, role: "admin")
        ]
      end

      before do
        allow_any_instance_of(Membership)
          .to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(Membership.new))
      end

      it "rolls back the user update" do
        expect(result[:success]).to be(false)
        user.reload
        expect(user.status).to eq("active")
        expect(user.memberships.pluck(:status).uniq).to eq(["active"])
      end
    end
  end
end


