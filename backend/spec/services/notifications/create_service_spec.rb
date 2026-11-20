require "rails_helper"

RSpec.describe Notifications::CreateService do
  let(:user) { create(:user) }
  let(:notification_type) { "group_invitation" }
  let(:message) { "Test Group Notification" }

  let(:result) {
    described_class.new(
      user: user,
      notification_type: notification_type,
      message: message
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do

      it "creates an notification successfully" do
        expect(result[:success]).to be(true)
        expect(result[:notification]).to be_persisted
        expect(result[:notification].notification_type).to eq(notification_type)
        expect(result[:notification].message).to eq(message)
        expect(result[:notification].user_id).to eq(user.id)
        expect(result[:notification].read).to be(false)
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

    context "when notification type is missing" do
      let(:notification_type) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Notification type must be one of: #{Notification::NOTIFICATION_TYPES.join(', ')}"
        )
      end
    end

    context "when notification type is invalid" do
      let(:notification_type) { "invalid-type" }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Notification type must be one of: #{Notification::NOTIFICATION_TYPES.join(', ')}"
        )
      end
    end

    context "when message is missing" do
      let(:message) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Message is required"
        )
      end
    end
  end
end