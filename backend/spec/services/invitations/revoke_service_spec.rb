require "rails_helper"

RSpec.describe Invitations::RevokeService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:group) { create(:group)}
  let!(:membership) do
    [
      create(:membership, group: group, user: user, role: "admin"),
      create(:membership, group: group, user: user2, role: "admin")
    ]
  end
  
  let!(:invitation) { create(:invitation, group: group, invited_by: user) }

  let(:result) {
    described_class.new(
      invitation: invitation,
      user: user
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      let(:result) {
        described_class.new(
          invitation: invitation,
          user: user2
        ).call
      }
      it "revokes the invitation" do
        expect(result[:success]).to be(true)
        expect(result[:invitation]).to be_persisted
        expect(result[:invitation].revoked_at).to be_present
        expect(result[:invitation].status).to eq("revoked")
        expect(result[:invitation].responded_at).to be_nil
      end
    end

    context "when invitation is missing" do
      let(:invitation) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invitation is required"
        )
      end
    end

    context "when invitation is revoked" do
      let(:invitation) { create(:invitation, status: "revoked") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invitation must be pending"
        )
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived)}

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group must be active"
        )
      end
    end

    context "when user is missing" do
      let(:user) { nil }
      let!(:membership) { nil }
      let!(:invitation) { create(:invitation) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is required"
        )
      end
    end

    context "when the user has deactivated account" do
      let(:user) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account"
        )
      end
    end

    context "when the user is not an active admin member of the group" do
      before do
        membership.first.update!(status: "inactive")
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is not an active admin member of the group"
        )
      end
    end
    
  end
end