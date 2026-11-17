require "rails_helper"

RSpec.describe Groups::CreateService do
  let(:name) { "Test Group" }
  let(:creator) { create(:user) }
  let(:description) { "Test Description" }

  let(:result) {
    described_class.new(
      name: name,
      creator: creator,
      description: description
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      
      it "creates a group and its memberships successfully" do
        expect(result[:success]).to be(true)
        expect(result[:group]).to be_persisted
        expect(result[:group].memberships.count).to eq(1)
        expect(result[:group].name).to eq(name)
        expect(result[:group].description).to eq(description)
        expect(result[:group].memberships.first).to have_attributes(
          user_id: creator.id,
          status: "active",
          role: "admin"
        )
      end
    end
    
    context "when creating a membership fails" do
      before do
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
          .to receive(:create!)
          .and_raise(ActiveRecord::RecordInvalid.new(Membership.new))
      end

      it "rolls back the group creation" do
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