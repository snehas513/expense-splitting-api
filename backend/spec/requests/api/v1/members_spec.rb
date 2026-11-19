require "rails_helper"

RSpec.describe "Memberships API", type: :request do
  describe "GET /api/v1/groups/:group_id/members" do
    let(:group) { create(:group) }
    let(:user1) { create(:user) }

    let(:user_token) { JsonWebToken.encode({ user_id: user1.id }) }

    context "lists group memberships" do
      let!(:memberships) do
        create_list(:membership, 10, group: group)
      end

      let!(:user1_membership) { create(:membership, group: group, user: user1) }

      it "returns success" do
        get "/api/v1/groups/#{group.id}/members",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expected_group_memberships = json["group_memberships"]
        expect(expected_group_memberships.count).to eq(11)
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        get "/api/v1/groups/#{-1}/members",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups/#{group.id}/members",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user has no membership" do

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/members",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Authenticated user, but no active membership")
      end
    end
    
  end

  describe "POST /api/v1/groups/:group_id/leave" do
    let(:group) { create(:group) }
    let(:user1) { create(:user) }

    let(:user_token) { JsonWebToken.encode({ user_id: user1.id }) }

    context "leave group" do
      let!(:user1_membership) { create(:membership, group: group, user: user1) }

      it "returns success" do
        post "/api/v1/groups/#{group.id}/leave",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expected_group_membership = json["membership"]
        expect(expected_group_membership["status"]).to eq("inactive")
        expect(expected_group_membership["role"]).to eq("member")
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        post "/api/v1/groups/#{-1}/leave",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        post "/api/v1/groups/#{group.id}/leave",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user has no membership" do

      it "returns unprocessable_entity" do
        post "/api/v1/groups/#{group.id}/leave",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "User is not an active member of the group"
        )
      end
    end
    
  end
end