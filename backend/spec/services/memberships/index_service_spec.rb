require "rails_helper"

RSpec.describe Memberships::IndexService do
  let(:group) { create(:group) }

  let(:result) {
    described_class.new(
      group: group
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

      it "returns group memberships" do
        expect(result[:success]).to be(true)
        expect(result[:group_memberships].count).to eq(17)
        expect(result[:group_memberships].pluck(:role).uniq).to eq(["admin", "member"])
        expect(result[:group_memberships].pluck(:status).uniq).to eq(["active", "inactive"])
      end
    end

    context "when a user has multiple membership records" do
      let(:user1) { create(:user) }

      let!(:memberships) do
        first = create(:membership, group: group, user: user1, role: "admin")
        second = create(:membership, :inactive, group: group, user: user1, role: "member")
        first.update!(status: "inactive")

        third = create(:membership, group: group, user: user1, role: "admin")
        [first, second, third]
      end

      it "returns only the latest membership per user" do
        expect(result[:success]).to be(true)
        expect(result[:group_memberships].count).to eq(1)
        expect(result[:group_memberships].first.id).to eq(memberships.third.id)
        expect(result[:group_memberships].first.role).to eq(memberships.third.role)
        expect(result[:group_memberships].first.status).to eq(memberships.third.status)
      end
    end

    context "when the group is missing" do
      let(:group) { nil }

      it "lists pending invitations" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when the group is archived" do
      let(:group) { create(:group, :archived) }

      it "lists pending invitations" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
      end
    end
  end
end