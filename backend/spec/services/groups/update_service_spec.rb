require "rails_helper"

RSpec.describe Groups::UpdateService do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:attributes) { { "name": "Update Group Name", "description": "Update Group Description"} }


  let(:result) {
    described_class.new(
      user: user,
      group: group,
      attributes: attributes
    ).call
  }

  describe "#call" do
    
    context "update user group details" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }

      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:group].id).to eq(group.id)
        expect(result[:group].name).to eq(attributes[:name])
        expect(result[:group].description).to eq(attributes[:description])
      end
    end

    context "update user group description to null" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }
      let(:attributes) { { "description": nil} }


      it "returns success" do
        expect(result[:success]).to be(true)
        expect(result[:group].id).to eq(group.id)
        expect(result[:group].name).to eq(group.name)
        expect(result[:group].description).to be_nil
      end
    end

    context "update user group name to null" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }
      let(:attributes) { { "name": nil} }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Name can't be blank"
        )
        original_name = group.name
        expect(group.reload.name).to eq(original_name)
      end
    end

    context "when the attributes is missing" do
      let(:attributes) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Valid update attributes are required"
        )
      end
    end

    context "when attributes is not a hash" do
      let(:attributes) { [] }

      it "returns an error" do
        expect(result[:success]).to be(false)
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

    context "when the user role is member" do
      let!(:membership) { create(:membership, group: group, user: user, role: "member") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:group]).to be_nil
      end
    end
  end
end