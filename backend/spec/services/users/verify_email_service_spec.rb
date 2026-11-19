require "rails_helper"

RSpec.describe Users::VerifyEmailService do
  include ActiveSupport::Testing::TimeHelpers

  let(:raw_token) { SecureRandom.urlsafe_base64(32) }

  let(:user) do
    token_digest = Digest::SHA256.hexdigest(raw_token)
    expires_at = 30.minutes.from_now

    create(:user, pending_email: "new_email@test.in", email_verification_token_digest: token_digest, email_verification_token_expires_at: expires_at)
  end
  
  let(:result) {
    described_class.new(
      user: user,
      raw_token: raw_token
    ).call
  }

  describe "#call" do

    context "when all attributes are valid" do
      
      it "returns success" do
        expect {
          result
        }.to have_enqueued_mail(UserMailer, :email_change_confirmation)

        expect(result[:success]).to be(true)
        user.reload
        expect(user.pending_email).to be_nil
        expect(user.email_verification_token_digest).to be_nil
        expect(user.email_verification_token_expires_at).to be_nil
        expect(user.email).to eq("new_email@test.in")
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

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User must have an active account"
        )
      end
    end

    context "when raw token is missing" do
      let(:user) { create(:user) }
      let(:raw_token) { nil }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Raw token is required"
        )
      end
    end

    context "when stored token digest is missing" do
      let(:user) do
        create(
          :user,
          pending_email: "new_email@test.in",
          email_verification_token_expires_at: 30.minutes.from_now
        )
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Raw token is invalid")
      end
    end

    context "when pending email is missing" do
      before do
        user.update!(pending_email: nil)
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Raw token is invalid"
        )
      end
    end

    context "when verification token has expired" do
      before do
        user.update!(email_verification_token_expires_at: 1.minute.ago)
      end     

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Verification token has expired"
        )
      end
    end

    context "when raw token is invalid" do
      let(:result) {
        described_class.new(
          user: user,
          raw_token: "invalid-token"
        ).call
      } 

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Raw token is invalid"
        )
      end
    end

    context "when updating user fails" do
      before do
        user.errors.add(:base, "Update failed")

        allow(user).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(user))
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Update failed")
      end
    end
  end

end

