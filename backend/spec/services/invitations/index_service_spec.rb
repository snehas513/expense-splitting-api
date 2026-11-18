require "rails_helper"

RSpec.describe Invitations::IndexService do
  let(:invited_by) { create(:user) }
  let(:group) { create(:group) }

  let(:result) {
    described_class.new(
      group: group,
      user: invited_by
    ).call
  }

  describe "#call" do
  
    context "when all attributes are valid" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin") }

      let!(:invitation) do
        create_list(:invitation, 15, group: group, invited_by: invited_by)
      end

      it "lists pending invitations" do
        expect(result[:success]).to be(true)
        expect(result[:invitations].count).to eq(15)
        expect(result[:invitations].pluck(:status).uniq).to eq(["pending"])
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

    context "when group is missing" do
      let(:group) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Group is required"
        )
      end
    end

    context "when user is missing" do
      let(:invited_by) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is required"
        )
      end
    end

    context "when the user has deactivated account" do
      let(:invited_by) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account"
        )
      end
    end

    context "when the user is an inactive admin member of the group" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin", status: "inactive") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is not an active admin member of the group"
        )
      end
    end
    
  end
end