require "rails_helper"

RSpec.describe Memberships::UpdateService do
  let(:group) { create(:group) }
  let(:admin) { create(:user) }
  let(:user) { create(:user) }
  let(:role) { nil }

  let(:result) {
    described_class.new(
      group: group,
      admin: admin,
      user: user,
      role: role
    ).call
  }

  describe "#call" do
  
    context "when promoting a member" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user) }
      let(:role) { "admin" }

      it "promotes the user's role as admin" do
        expect(result[:success]).to be(true)
        expect(result[:membership].status).to eq("active")
        expect(result[:membership].role).to eq(role)
        expect(user_membership.reload.role).to eq(role)
      end
    end

    context "when demoting another admin" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user, role: "admin") }
      let(:role) { "member" }

      it "demotes the user's role as member" do
        expect(result[:success]).to be(true)
        expect(result[:membership].status).to eq("active")
        expect(result[:membership].role).to eq(role)
        expect(user_membership.reload.role).to eq(role)
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

    context "when a regular member cannot perform the role change" do
      let!(:admin_membership) { create(:membership, :inactive, group: group, user: admin, role: "member") }

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

    context "when the user has inactive membership" do
      let!(:user_membership) { create(:membership, :inactive, group: group, user: user) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is not an active member of the group")
      end
    end

    context "when the admin tries to demote themselves" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let(:user) { admin }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Admin cannot change their own role")
        expect(admin_membership.reload.role).to eq("admin")
      end
    end

    context "when the admin tries to demote/promote the respective role" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user, role: "member") }
      let(:role) { "member" }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User already has this role")
      end
    end

    context "when the admin tries to demote/promote to an invalid role" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user, role: "member") }
      let(:role) { "super user" }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Role must be one of: member, admin")
      end
    end
  end
end