require "rails_helper"

RSpec.describe Groups::IndexService do
  let(:user) { create(:user) }

  let(:result) {
    described_class.new(
      user: user
    ).call
  }

  describe "#call" do
    
    context "list groups" do
      let!(:groups) do
        create_list(:group, 10).each do |group|
          create(:membership, group: group, user: user)
        end
      end

      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:groups].count).to eq(10)
        expect(result[:groups].pluck(:id)).to eq(groups.pluck(:id))
      end
    end

    context "whne an user's active groups are returned" do
      let!(:groups) do
        active = create_list(:group, 10).each do |group|
          create(:membership, group: group, user: user)
        end

        archived = create_list(:group, 5, :archived).each do |group|
          create(:membership, group: group, user: user)
        end
        active + archived
      end

      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:groups].count).to eq(groups.count { |s| s.status == "active" })
        expect(result[:groups].pluck(:id)).to eq(groups.select { |s| s.status == "active" }.pluck(:id))
      end
    end

    context "whne there is a group where the user's membership is inactive is excluded" do
      let!(:group1) { create(:group) }
      let!(:group2) { create(:group) }

      let!(:memberships) do
        [
          create(:membership, group: group1, user: user),
          create(:membership, :inactive, group: group2, user: user)
        ]
      end

      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:groups].count).to eq(1)
        expect(result[:groups].first.id).to eq(group1.id)
      end
    end
  end
end