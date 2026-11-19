require "rails_helper"

RSpec.describe Users::RequestEmailChangeService do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:new_email) { "   new_email@test.in  " }

  let(:result) {
    described_class.new(
      user: user,
      new_email: new_email
    ).call
  }

  describe "#call" do

    context "when all attributes are valid" do
      
      it "returns success" do
        travel_to(Time.zone.now) do
          expect {
            result
          }.to have_enqueued_mail(UserMailer, :email_verification)

          normalized_new_email = new_email&.strip&.downcase
          expect(result[:success]).to be(true)
          user.reload
          expect(user.pending_email).to eq(normalized_new_email)
          expect(user.email_verification_token_digest.size).to eq(64)
          expect(user.email_verification_token_expires_at).to eq(30.minutes.from_now)
          expect(user.email).not_to eq(normalized_new_email)
        end
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

    context "when new email is missing" do
      let(:new_email) { nil }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "New Email is required"
        )
      end
    end

    context "when new email format is invalid" do
      let(:new_email) { "invalid-email" }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Invalid email format"
        )
      end
    end

    context "when new email is same current email" do
      let(:new_email) { user.email }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "New email must be different from current email"
        )
      end
    end

    context "when new email is same as another user's email" do
      let(:user1) { create(:user) }
      let(:new_email) { user1.email }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Email has already been taken"
        )
      end
    end

    context "when new email is same as another user's pending email" do
      let!(:user1) { create(:user, pending_email: "pending_email@test.in") }
      let(:new_email) { user1.pending_email }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Email has already been taken"
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

