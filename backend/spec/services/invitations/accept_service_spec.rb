require "rails_helper"

RSpec.describe Invitations::AcceptService do
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

      it "accepts the invitation and creates an active membership" do
        expect(result[:success]).to be(true)
        expect(result[:invitation]).to be_persisted
        expect(result[:invitation].responded_at).to be_present
        expect(result[:invitation].status).to eq("accepted")

        membership = result[:invitation].group.memberships.find_by(user_id: invitation.invited_user_id)
        expect(membership).to be_present
        expect(membership).to have_attributes(
          status: "active",
          role: "member"
        )
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

    context "when invitation is accepted" do
      let(:invitation) { create(:invitation, status: "accepted") }

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

    context "when membership creation fails" do

      before do
        allow_any_instance_of(Group)
          .to receive_message_chain(:memberships, :create!)
          .and_raise(ActiveRecord::RecordInvalid.new(Membership.new))
      end

      it "rolls back the invitation and membership updates" do
        invitation_count = Invitation.count
        membership_count = Membership.count

        response = result
        expect(response[:success]).to be(false)
        expect(invitation.reload.status).to eq("pending")
        expect(invitation.responded_at).to be_nil
        expect(Invitation.count).to eq(invitation_count)
        expect(Membership.count).to eq(membership_count)
      end
    end
    
  end
end