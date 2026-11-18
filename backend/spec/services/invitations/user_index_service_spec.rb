require "rails_helper"

RSpec.describe Invitations::UserIndexService do
  let(:user) { create(:user) }

  let(:result) {
    described_class.new(
      user: user
    ).call
  }

  describe "#call" do
  
    context "when all attributes are valid" do

      let!(:invitation) do
        rejected = create_list(:invitation, 10, invited_user: user, status: "rejected")
        pending = create_list(:invitation, 15, invited_user: user)
        rejected + pending
      end

      it "lists user's pending invitations" do
        expect(result[:success]).to be(true)
        expect(result[:invitations].count).to eq(15)
        expect(result[:invitations].pluck(:status).uniq).to eq(["pending"])
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
    
  end
end