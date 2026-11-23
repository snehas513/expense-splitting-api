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

  describe "GET groups/:group_id/balances/:member_id" do
    let(:group) { create(:group) }
    let(:user) { create(:user) }
    let(:member) { create(:user) }

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when the user is an active group member" do
      let!(:memberships) do
        [member, user].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: member, payer: member, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: user, payer: user, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 750
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [member, user].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 450
          )
        end
      end

      it "returns success" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to be(true)
        expect(json["breakdown"]).to be_a(Hash)
        breakdown = json["breakdown"]
        expect(breakdown).to have_key("user_owes_member")
        expect(breakdown).to have_key("member_owes_user")
        expect(breakdown["outstanding_debt"]).to be_a(String)
        expect(breakdown["outstanding_debt"]).to eq("300.0")
        expect(breakdown["user_owes_member"].first["remaining_amount"]).to eq("750.0")
        expect(breakdown["member_owes_user"].first["remaining_amount"]).to eq("450.0")
      end
    end

    context "when there is no authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        as: :json

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Unauthorized")
      end
    end

    context "when an authenticated user has no membership" do

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Authenticated user, but no active membership")
      end
    end

    context "when the group doesn't exist" do

      it "returns not found" do
        get "/api/v1/groups/#{-1}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Group not found")
      end
    end

    context "when an authenticated user has an inactive membership" do
      let!(:membership) do
        create(:membership, :inactive, group: group, user: user)
      end

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when member doesn't exist" do
      let!(:membership) do
        create(:membership, group: group, user: user)
      end

      it "returns unprocessable_entity" do
        get "/api/v1/groups/#{group.id}/balances/#{-1}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when member is not active member of the group" do
      let!(:membership) do
        [
          create(:membership, group: group, user: user)
        ]
      end

      it "returns unprocessable_entity" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when member is inactive member of the group" do
      let!(:membership) do
        [
          create(:membership, group: group, user: user),
          create(:membership, :inactive, group: group, user: member)
        ]
      end

      it "returns unprocessable_entity" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when member is inactive member of the group" do
      let(:member) { create(:user, :deactivated) }
      let!(:membership) do
        [
          create(:membership, group: group, user: user),
          create(:membership, group: group, user: member)
        ]
      end

      it "returns unprocessable_entity" do
        get "/api/v1/groups/#{group.id}/balances/#{member.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end