require "rails_helper"

RSpec.describe "Invitations API", type: :request do
  describe "POST /api/v1/groups/:group_id/invitations" do
    let(:group) { create(:group) }
    let(:invited_by) { create(:user) }
    let(:invited_user) { create(:user) }

    let(:invited_by_token) { JsonWebToken.encode({ user_id: invited_by.id }) }

    context "creates an invitation successfully" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin") }

      it "returns success" do
        expect {
          post "/api/v1/groups/#{group.id}/invitations",
          headers: { 
            "Authorization" => "Bearer #{invited_by_token}"
          },
          params: {
            "invited_user_id": invited_user.id
          },
          as: :json
        }.to change(Invitation, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)

        expected_invitation = json["invitation"]

        expect(expected_invitation["invited_by"]).to include(
          "id" => invited_by.id,
          "name" => invited_by.name
        )
        expect(expected_invitation["invited_user"]).to include(
          "id" => invited_user.id,
          "name" => invited_user.name
        )
        expect(expected_invitation["group"]).to include(
          "id" => group.id,
          "name" => group.name
        )
        expect(expected_invitation["status"]).to eq("pending")
      end
    end

    context "when the group does not exist" do

      it "returns not_found" do

        invitations_before = Invitation.count
        post "/api/v1/groups/#{-1}/invitations",
          headers: { 
            "Authorization" => "Bearer #{invited_by_token}"
          },
          params: {
            "invited_user_id": invited_user.id
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Invitation.count).to eq(invitations_before)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        invitations_before = Invitation.count
        post "/api/v1/groups/#{group.id}/invitations",
          params: {
            "invited_user_id": invited_user.id
          },
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Invitation.count).to eq(invitations_before)
      end
    end
    
  end

  describe "POST /api/v1/groups/:group_id/invitations/:id/accept" do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let!(:invitation) { create(:invitation, group: group, invited_user: user) }

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "accepts the invitation" do

      it "returns success" do
        post "/api/v1/groups/#{group.id}/invitations/#{invitation.id}/accept",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)

        expected_invitation = json["invitation"]

        expect(expected_invitation["status"]).to eq("accepted")
        expect(expected_invitation["responded_at"]).to be_present

        membership = invitation.reload.group.memberships.find_by(user_id: invitation.invited_user_id)
        expect(membership).to be_present
        expect(membership).to have_attributes(
          status: "active",
          role: "member"
        )
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        post "/api/v1/groups/#{-1}/invitations/#{invitation.id}/accept",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when invitation does not exist" do

      it "returns unprocessable entity" do
        post "/api/v1/groups/#{group.id}/invitations/#{-1}/accept",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        invitations_before = Invitation.count
        post "/api/v1/groups/#{group.id}/invitations/#{invitation.id}/accept",
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Invitation.count).to eq(invitations_before)
      end
    end
  end

  describe "POST /api/v1/groups/:group_id/invitations/:id/reject" do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let!(:invitation) { create(:invitation, group: group, invited_user: user) }

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "rejects the invitation" do

      it "returns success" do
        post "/api/v1/groups/#{group.id}/invitations/#{invitation.id}/reject",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)

        expected_invitation = json["invitation"]

        expect(expected_invitation["status"]).to eq("rejected")
        expect(expected_invitation["responded_at"]).to be_present

        membership = invitation.reload.group.memberships.find_by(user_id: invitation.invited_user_id)
        expect(membership).to be_nil
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        post "/api/v1/groups/#{-1}/invitations/#{invitation.id}/reject",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when invitation does not exist" do

      it "returns unprocessable entity" do
        post "/api/v1/groups/#{group.id}/invitations/#{-1}/reject",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        invitations_before = Invitation.count
        post "/api/v1/groups/#{group.id}/invitations/#{invitation.id}/reject",
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Invitation.count).to eq(invitations_before)
      end
    end
  end

  describe "GET /api/v1/groups/:group_id/invitations" do
    let(:invited_by) { create(:user) }
    let(:group) { create(:group) }

    let(:user_token) { JsonWebToken.encode({ user_id: invited_by.id }) }

    context "when the admin lists pending invitations" do
      let!(:membership) { create(:membership, group: group, user: invited_by, role: "admin") }

      let!(:invitation) do
        create_list(:invitation, 15, group: group, invited_by: invited_by)
      end

      it "returns success" do
        get "/api/v1/groups/#{group.id}/invitations",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)

        expected_invitations = json["invitations"]
        expect(expected_invitations.count).to eq(15)
        expect(expected_invitations.pluck("status").uniq).to eq(["pending"])
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        get "/api/v1/groups/#{-1}/invitations",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups/#{group.id}/invitations",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user has no membership" do

      it "returns unprocessable_entity" do
        get "/api/v1/groups/#{group.id}/invitations",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("User is not an active admin member of the group")
      end
    end
  end

  describe "GET /api/v1/invitations" do
    let(:user) { create(:user) }

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when the user lists pending invitations" do
      let!(:invitation) do
        rejected = create_list(:invitation, 10, invited_user: user, status: "rejected")
        pending = create_list(:invitation, 15, invited_user: user)
        rejected + pending
      end

      it "returns success" do
        get "/api/v1/invitations",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)

        expected_invitations = json["invitations"]
        expect(expected_invitations.count).to eq(15)
        expect(expected_invitations.pluck("status").uniq).to eq(["pending"])
        expect(expected_invitations.pluck("invited_user", "id")).to be_present
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/invitations",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/groups/:group_id/invitations/:id/revoke" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:group) { create(:group)}
    let!(:membership) do
      [
        create(:membership, group: group, user: user, role: "admin"),
        create(:membership, group: group, user: user2, role: "admin")
      ]
    end
  
    let!(:invitation) { create(:invitation, group: group, invited_by: user) }
    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }
    let(:user2_token) { JsonWebToken.encode({ user_id: user2.id }) }

    context "revokes the invitation" do

      it "returns success" do
        post "/api/v1/groups/#{group.id}/invitations/#{invitation.id}/revoke",
          headers: { 
            "Authorization" => "Bearer #{user2_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)

        expected_invitation = json["invitation"]

        expect(expected_invitation["status"]).to eq("revoked")
        expect(expected_invitation["revoked_at"]).to be_present
        expect(expected_invitation["responded_at"]).to be_nil
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        post "/api/v1/groups/#{-1}/invitations/#{invitation.id}/revoke",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when invitation does not exist" do

      it "returns unprocessable entity" do
        post "/api/v1/groups/#{group.id}/invitations/#{-1}/revoke",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        invitations_before = Invitation.count
        post "/api/v1/groups/#{group.id}/invitations/#{invitation.id}/revoke",
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Invitation.count).to eq(invitations_before)
      end
    end
  end
end