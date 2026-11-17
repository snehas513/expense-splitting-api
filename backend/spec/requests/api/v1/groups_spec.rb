require "rails_helper"

RSpec.describe "Groups API", type: :request do
  describe "POST /api/v1/groups" do
    let(:name) { "Test Group" }
    let(:creator) { create(:user) }
    let(:description) { "Test Description" }

    let(:creator_token) { JsonWebToken.encode({ user_id: creator.id }) }

    context "creates a group and its memberships successfully" do

      it "returns success" do
        expect {
          post "/api/v1/groups",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "name": name,
            "description": description
          },
          as: :json
        }.to change(Group, :count).by(1)
          .and change(Membership, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expected_group = json["group"]
        expect(expected_group["name"]).to eq(name)
        membership = Membership.find_by(
          group_id: expected_group["id"],
          user_id: creator.id
        )

        expect(membership).to have_attributes(
          role: "admin",
          status: "active"
        )
      end
    end

    context "when the group name already exist" do
      let!(:group) { create(:group, name: "Test Group") }

      it "returns an error" do
        groups_before = Group.count
        memberships_before = Membership.count

        post "/api/v1/groups",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "name": name,
            "description": description
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Group.count).to eq(groups_before)
        expect(Membership.count).to eq(memberships_before)        
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        groups_before = Group.count
        memberships_before = Membership.count
        post "/api/v1/groups",
          params: {
            "name": name,
            "description": description
          },
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Group.count).to eq(groups_before)
        expect(Membership.count).to eq(memberships_before)     
      end
    end
    
  end

  describe "GET /api/v1/groups/:group_id" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "list groups" do
      let!(:active_groups) do
        create_list(:group, 3).each do |group|
          create(:membership, group: group, user: user)
        end
      end

      let!(:archived_groups) do
        create_list(:group, 5, :archived).each do |group|
          create(:membership, group: group, user: user)
        end
      end

      let!(:user2_group) { create(:group) } 
      let!(:user2_group_membership) { create(:membership, group: user2_group, user: user2) }

      it "returns success" do
        get "/api/v1/groups",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        response_groups = json["groups"]
        expect(response_groups.count).to eq(3)
        expect(response_groups.pluck("id")).to match_array(
          active_groups.map { |group| group.id }
        )
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
    
  end

  describe "GET /api/v1/groups" do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when group is present" do
      let!(:membership) { create(:membership, group: group, user: user) }

      it "returns success" do
        get "/api/v1/groups/#{group.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        response_group = json["group"]
        expect(response_group["id"]).to eq(group.id)
        expect(response_group["name"]).to eq(group.name)
      end
    end

    context "when group does not exist" do
      let!(:membership) { create(:membership, group: group, user: user) }

      it "returns not found" do
        get "/api/v1/groups/#{-1}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is not a member of the group" do

      it "returns unprocessable_entity" do
        get "/api/v1/groups/#{group.id}",
          headers: { 
            "Authorization" => "Bearer #{user_token}"
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups/#{group.id}",
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
    
  end

  describe "PATCH /api/v1/groups" do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:attributes) do
      { "name"=> "Update Group Name", "description"=> "Update Group Description"} 
    end

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "update group name and description" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }

      it "returns success" do
        patch "/api/v1/groups/#{group.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: attributes,
        as: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        response_group = json["group"]
        expect(response_group["id"]).to eq(group.id)
        expect(response_group["name"]).to eq(attributes["name"])
        expect(group.reload.description).to eq(attributes["description"])
      end
    end

    context "update group description" do
      let!(:membership) { create(:membership, group: group, user: user, role: "admin") }
      let(:attributes) do
        { "description"=> "Update Group Description"} 
      end
      it "returns success" do
        patch "/api/v1/groups/#{group.id}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: attributes,
        as: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        response_group = json["group"]
        expect(response_group["id"]).to eq(group.id)
        expect(response_group["name"]).to eq(group.name)
        expect(group.reload.description).to eq(attributes["description"])
      end
    end

    context "when group does not exist" do

      it "returns not found" do
        patch "/api/v1/groups/#{-1}",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: attributes,
        as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        patch "/api/v1/groups/#{group.id}",
          params: attributes,
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
    
  end
end