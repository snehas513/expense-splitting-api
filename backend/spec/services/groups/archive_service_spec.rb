require "rails_helper"

RSpec.describe Groups::ArchiveService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  let(:result) {
    described_class.new(
      user: user,
      group: group
    ).call
  }

  describe "#call" do
    
    context "archive user group" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }

      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:group].id).to eq(group.id)
        expect(group.reload.status).to eq("archived")
        expect(group.reload.memberships.pluck(:status)).to include("inactive")
      end
    end

    context "when active member cannot archive the group" do
      let!(:membership) { create(:membership, group: group, user: user, role: "member") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(group.reload.status).to eq("active")
        expect(group.reload.memberships.pluck(:status)).to include("active")
        expect(result[:errors]).to include("Group not found or you are not an active admin")
      end
    end

    context "when an archived group cannot be archived again" do
      let(:group) { create(:group, :archived) }
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        original_status = group.status
        expect(group.reload.status).to eq(original_status)
      end
    end

    context "when membership update failure rolls back the group status" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }

      before do
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
          .to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(Membership.new))
      end

      it "rolls back the group and membership updates" do
        group_count = Group.count
        membership_count = Membership.count

        response = result
        expect(response[:success]).to be(false)
        expect(Group.count).to eq(group_count)
        expect(Membership.count).to eq(membership_count)
      end
    end
  end
end