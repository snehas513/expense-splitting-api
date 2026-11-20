require "rails_helper"

RSpec.describe Notifications::MarkAsReadService do
  let(:notification) { create(:notification, read: false) }

  let(:result) {
    described_class.new(
      notification: notification
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do

      it "marks the notification as read successfully"  do
        original_read = notification.read
        expect(result[:success]).to be(true)
        expect(result[:notification].read).to be(true)
        expect(result[:notification].reload.read).not_to be(original_read)
      end
    end

    context "when changing an already-read notification" do
      let(:notification) { create(:notification, read: true) }

      it "returns success without changing an already-read notification" do
        original_updated_at = notification.updated_at

        expect(result[:success]).to be(true)
        expect(notification.reload.read).to be(true)
        expect(notification.updated_at).to eq(original_updated_at)
      end
    end

    context "when notification is missing" do
      let(:notification) { nil }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Notification is required"
        )
      end
    end

  end
end