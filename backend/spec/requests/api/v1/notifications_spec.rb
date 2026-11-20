require "rails_helper"

RSpec.describe "Notifications API", type: :request do
  describe "GET /api/v1/notifications" do
    let(:user) { create(:user) }
    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when user is valid" do
      let!(:notifications) do
        unread = create_list(:notification, 5, user: user, read: false)
        read = create_list(:notification, 10, user: user, read: true)

        unread + read
      end
      it "returns success" do
        get "/api/v1/notifications",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["notifications"].count).to eq(5)
        expected_ids = notifications
                        .select {|notification| notification.read == false}
                        .sort_by { |notification| [notification.created_at, notification.id] }
                        .reverse
                        .map(&:id)
        expect(json["notifications"].pluck("id")).to eq(expected_ids)
        expected_notification = json["notifications"].first
        expect(expected_notification).not_to have_key("user_id")
        expect(expected_notification).not_to have_key("updated_at")
        expect(expected_notification.keys).to match_array(
          %w[id notification_type message read created_at]
        )
        expect(expected_notification.keys).not_to match_array(
          %w[user_id updated_at]
        )
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        get "/api/v1/notifications",
         headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/notifications",
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/notifications/:id/mark_as_read" do
    let(:user) { create(:user) }
    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }
    let(:notification) { create(:notification, user: user, read: false)}

    context "when notification is valid" do
      
      it "returns success" do
        patch "/api/v1/notifications/#{notification.id}/mark_as_read",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["notification"]["read"]).to be(true)
      end
    end

    context "when notification belongs to a different user" do
      let(:user1) { create(:user) }
      let(:notification) { create(:notification, user: user1, read: false)}

      it "returns unprocessable_entity" do
        patch "/api/v1/notifications/#{notification.id}/mark_as_read",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(notification.reload.read).to be(false)
      end
    end

    context "when notification does not exist" do
      
      it "returns an error" do
        patch "/api/v1/notifications/#{-1}/mark_as_read",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["success"]).to be(false)
        expect(notification.read).to be(false)
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        patch "/api/v1/notifications/#{notification.id}/mark_as_read",
         headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        patch "/api/v1/notifications/#{notification.id}/mark_as_read",
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end