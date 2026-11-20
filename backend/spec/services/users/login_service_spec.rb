
require "rails_helper"

RSpec.describe Users::LoginService do
  describe "#call" do
    let!(:user) { create(:user, email: "sneha@example.com", password: "password123", email_verified_at: Time.current) }
    
    let(:params) do
      {
        email: "sneha@example.com",
        password: "password123"
      }
    end

    subject(:result) { described_class.new(**params).call }

    context "when login is successful" do

      it "returns jwt" do
        expect(result[:success]).to be(true)
        expect(result[:user][:email_verified]).to be(true)
        expect(result[:auth_token]).to be_present
        decoded = JsonWebToken.decode(result[:auth_token])
        expect(decoded["user_id"]).to eq(user.id)
      end
    end

    context "when login fails" do
      let(:params) do
        {
          email: "neha@example.com",
          password: "password123"
        }
      end

      it "returns validation errors" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invalid email or password"
        )
      end
    end

    context "when user is deactivated" do
      before do
        user.update!(status: "deactivated")
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Your account is deactivated"
        )
      end
    end

    context "when user is unverified" do
      before do
        user.update!(email_verified_at: nil)
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Please verify your email before logging in"
        )
      end
    end
  end
end
