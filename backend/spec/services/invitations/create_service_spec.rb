require "rails_helper"

RSpec.describe Invitations::CreateService do
  let(:group) { create(:group) }
  let(:invited_by) { create(:user) }
  let(:invited_user) { create(:user) }

  let(:result) {
    described_class.new(
      group: group,
      invited_by: invited_by,
      invited_user: invited_user
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin") }

      it "creates an invitation successfully" do
        expect(result[:success]).to be(true)
        expect(result[:invitation]).to be_persisted
        expect(result[:invitation].group_id).to eq(group.id)
        expect(result[:invitation].invited_by_id).to eq(invited_by.id)
        expect(result[:invitation].invited_user_id).to eq(invited_user.id)
        expect(result[:invitation].status).to eq("pending")
      end
    end
    
    context "when Invited By is missing" do
      let(:invited_by) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited By is required"
        )
      end
    end

    context "when Invited By has a deactivated account" do
      let(:invited_by) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited by must have an active account and active admin membership in the group"
        )
      end
    end

    context "when Invited By has an inactive membership in the group" do
      let!(:membership) { create(:membership, :inactive, group: group, user: invited_by, role: "admin") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited by must have an active account and active admin membership in the group"
        )
      end
    end

    context "when Invited By is an active member but not an admin" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "member") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited by must have an active account and active admin membership in the group"
        )
      end
    end

    context "when Invited User is missing" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin") }
      let(:invited_user) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited User is required"
        )
      end
    end

    context "when Invited User has a deactivated account" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin") }
      let(:invited_user) { create(:user, :deactivated) } 

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited User must have an active account"
        )
      end
    end

    context "when Invited User is already an active member of the group" do
      let!(:membership) do
        [
          create(:membership, group: group, user: invited_by, role: "admin"),
          create(:membership, group: group, user: invited_user, role: "member")
        ]
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invited User is already an active member of the group"
        )
      end
    end

    context "when inviter tries to invite themselves" do
      let!(:membership) do
        [
          create(:membership, group: group, user: invited_by, role: "admin")
        ]
      end

      let(:result) {
        described_class.new(
          group: group,
          invited_by: invited_by,
          invited_user: invited_by
        ).call
      }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "A user cannot invite themselves"
        )
      end
    end

    context "when a pending invitation already exists" do
      let!(:membership) do
        [
          create(:membership, group: group, user: invited_by, role: "admin")
        ]
      end

      let!(:invitation) { create(:invitation, group: group, invited_by: invited_by, invited_user: invited_user) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Pending invitation already exists for this group/user"
        )
      end
    end

    context "when group is missing" do
      let(:group) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group is required"
        )
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group must be active"
        )
      end
    end

  end
end