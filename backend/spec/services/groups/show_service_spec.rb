require "rails_helper"

RSpec.describe Groups::ShowService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  let(:result) {
    described_class.new(
      user: user,
      group: group
    ).call
  }

  describe "#call" do
    
    context "fetch user group details" do
      let!(:membership) { create(:membership, group: group, user: user) }

      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:group].id).to eq(group.id)
        expect(result[:group].name).to eq(group.name)
      end
    end

    context "when the group is missing" do
      let(:group) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
      end
    end

    context "when the group is archived" do
      let(:group) { create(:group, :archived) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:group]).to be_nil
      end
    end

    context "when the group membership is inactive" do
      let!(:membership) { create(:membership, :inactive, group: group, user: user) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:group]).to be_nil
      end
    end
  end
end