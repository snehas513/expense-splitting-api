require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, pending_email: "pending_email@user.in") }

  describe ".email_verification" do
    let(:result) {
      described_class.email_verification(user: user, raw_token: "test-token", purpose: :email_change)
    }
         
    it "sends the verification email" do
      expect(result.to).to eq([user.pending_email])
      expect(result.subject).to eq("Verify your new email address")
      expect(result.body.encoded).to include("test-token")
      expect(result.body.encoded).to include("localhost:8501/verify-email")
    end
  end

  describe ".email_change_confirmation" do
    let(:result) {
      described_class.email_change_confirmation(user: user, purpose: :email_change)
    }

    it "sends the change confirmation email" do
      expect(result.to).to eq([user.email])
      expect(result.subject).to eq("Your email address has been updated")
      expect(result.body.encoded).to include(
        "Your email address has been verified and updated."
      )
    end
  end
end
