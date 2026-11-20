
require "rails_helper"

RSpec.describe Users::RegisterService do
  describe "#call" do
    let(:params) do
      {
        name: "Sneha",
        email: "sneha@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    subject(:result) { described_class.new(**params).call }

    context "when registration is successful" do
      it "creates an active, unverified user" do
        expect { result }.to change(User, :count).by(1)

        expect(result[:success]).to be(true)
        expect(result[:user]).to be_persisted
        expect(result[:user].status).to eq("active")
        expect(result[:user].email_verified_at).to be_nil
      end
    end

    context "when registration fails" do
      before do
        User.create!(
          name: "Existing User",
          email: "sneha@example.com",
          password: "password123"
        )
      end

      it "returns validation errors without creating a user" do
        expect { result }.not_to change(User, :count)
        expect(result[:success]).to be(false)
        expect(result[:errors]).to be_present
      end
    end
  end
end
