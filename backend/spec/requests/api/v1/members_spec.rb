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

  describe "DELETE /api/v1/groups/:group_id/members/:target_user_id" do
    let(:group) { create(:group) }
    let(:admin) { create(:user) }
    let(:user) { create(:user) }      

    let(:admin_token) { JsonWebToken.encode({ user_id: admin.id }) }

    context "remove member" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user) }

      it "returns success" do
        delete "/api/v1/groups/#{group.id}/members/#{user.id}",
        headers: { 
          "Authorization" => "Bearer #{admin_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expected_group_membership = json["membership"]
        expect(expected_group_membership["status"]).to eq("inactive")
        expect(expected_group_membership["role"]).to eq("member")
        expect(user_membership.reload.status).to eq("inactive")
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        delete "/api/v1/groups/#{-1}/members/#{user.id}",
          headers: { 
            "Authorization" => "Bearer #{admin_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when target user does not exist" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }

      it "returns unprocessable_entity" do
        delete "/api/v1/groups/#{group.id}/members/#{-1}",
          headers: { 
            "Authorization" => "Bearer #{admin_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "User is required"
        )
      end
    end
    context "when there is no Authorization header" do

      it "returns unauthorized" do
        delete "/api/v1/groups/#{group.id}/members/#{user.id}",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user has no membership" do

      it "returns unprocessable_entity" do
        delete "/api/v1/groups/#{group.id}/members/#{user.id}",
        headers: { 
          "Authorization" => "Bearer #{admin_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Admin is not an active admin member of the group"
        )
      end
    end

    context "when an authenticated user is a regular member" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "member") }

      it "returns unprocessable_entity" do
        delete "/api/v1/groups/#{group.id}/members/#{user.id}",
        headers: { 
          "Authorization" => "Bearer #{admin_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Admin is not an active admin member of the group"
        )
      end
    end
    
  end

  describe "PATCH /api/v1/groups/:group_id/members/:target_user_id/role" do
    let(:group) { create(:group) }
    let(:admin) { create(:user) }
    let(:user) { create(:user) }
    let(:role) { nil }      

    let(:admin_token) { JsonWebToken.encode({ user_id: admin.id }) }

    context "promote a member" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
      let!(:user_membership) { create(:membership, group: group, user: user, role: "member") }
      let(:role) { "admin" }

      it "returns success" do
        patch "/api/v1/groups/#{group.id}/members/#{user.id}/role",
        headers: { 
          "Authorization" => "Bearer #{admin_token}"
        },
        params: {
          "role": role
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expected_group_membership = json["membership"]
        expect(expected_group_membership["role"]).to eq("admin")
        expect(user_membership.reload.role).to eq(role)
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        patch "/api/v1/groups/#{-1}/members/#{user.id}/role",
          headers: { 
            "Authorization" => "Bearer #{admin_token}"
          },
          params: {
            "role": role
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when target user does not exist" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }

      it "returns unprocessable_entity" do
        patch "/api/v1/groups/#{group.id}/members/#{-1}/role",
          headers: { 
            "Authorization" => "Bearer #{admin_token}"
          },
          params: {
            "role": role
          },
          as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "User is required"
        )
      end
    end
    context "when there is no Authorization header" do

      it "returns unauthorized" do
        patch "/api/v1/groups/#{group.id}/members/#{user.id}/role",
          params: {
            "role": role
          },
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user has no membership" do

      it "returns unprocessable_entity" do
        patch "/api/v1/groups/#{group.id}/members/#{user.id}/role",
        headers: { 
          "Authorization" => "Bearer #{admin_token}"
        },
        params: {
          "role": role
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Admin is not an active admin member of the group"
        )
      end
    end

    context "when an authenticated user is a regular member" do
      let!(:admin_membership) { create(:membership, group: group, user: admin, role: "member") }

      it "returns unprocessable_entity" do
        patch "/api/v1/groups/#{group.id}/members/#{user.id}/role",
        headers: { 
          "Authorization" => "Bearer #{admin_token}"
        },
        params: {
          "role": role
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Admin is not an active admin member of the group"
        )
      end
    end
    
  end
end