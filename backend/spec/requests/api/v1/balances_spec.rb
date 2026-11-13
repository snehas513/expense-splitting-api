require "rails_helper"

RSpec.describe "Balances API", type: :request do
  describe "GET /api/v1/groups/:group_id/balances" do
    let(:group) { create(:group) }
    let(:creator) { create(:user) }
    let(:creator_token) { JsonWebToken.encode({ user_id: creator.id }) }

    context "when the user is an active group member" do
      let!(:membership) do
        create(:membership, group: group, user: creator)
      end

      it "returns success" do
        get "/api/v1/groups/#{group.id}/balances",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to be(true)
        expect(json["balances"]).to be_a(Array)
        expect(json["balances"]).to include(
          {
            "user_id" => creator.id,
            "name" => creator.name,
            "balance" => "0.00"
          }
        )
      end
    end

    context "when there is no authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups/#{group.id}/balances",
        as: :json

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Unauthorized")
      end
    end

    context "when an authenticated user has no membership" do

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/balances",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Authenticated user, but no active membership")
      end
    end

    context "when the group doesn't exist" do

      it "returns not found" do
        get "/api/v1/groups/#{-1}/balances",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Group not found")
      end
    end

    context "when an authenticated user has an inactive membership" do
      let!(:membership) do
        create(:membership, :inactive, group: group, user: creator)
      end

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/balances",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end