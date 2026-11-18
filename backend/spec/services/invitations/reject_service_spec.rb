require "rails_helper"

RSpec.describe Invitations::RejectService do
  let!(:invitation) { create(:invitation) }
  let(:user) { invitation&.invited_user }

  let(:result) {
    described_class.new(
      invitation: invitation,
      user: user
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do

      it "rejects the invitation" do
        expect(result[:success]).to be(true)
        expect(result[:invitation]).to be_persisted
        expect(result[:invitation].responded_at).to be_present
        expect(result[:invitation].status).to eq("rejected")

        membership = result[:invitation].group.memberships.find_by(user_id: invitation.invited_user_id)
        expect(membership).to be_nil
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

    context "when invitation is rejected" do
      let(:invitation) { create(:invitation, status: "rejected") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invitation must be pending"
        )
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived)}
      let(:invitation) { create(:invitation, group: group) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group must be active"
        )
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

    context "when the user has deactivated account" do
      let(:user) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account"
        )
      end
    end

    context "when the user is not the invited user" do
      let(:user) { create(:user) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is invalid"
        )
      end
    end

    context "when the user is already an active member of the group" do
      let!(:membership) { create(:membership, group: invitation.group, user: user, role: "member") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is already an active member of the group"
        )
      end
    end

    context "when invitation update fails" do
      it "does not change the invitation status" do
        allow(invitation).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(invitation))

        expect(result[:success]).to be(false)
        expect(invitation.reload.status).to eq("pending")
      end
    end
    
  end
end