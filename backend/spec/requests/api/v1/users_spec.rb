require "rails_helper"

RSpec.describe "Users API", type: :request do
  describe "GET /api/v1/users/me" do
    let(:user) { create(:user) }
    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when user is valid" do
      it "returns success" do
        get "/api/v1/users/me",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expected_user = json["user"]
        expect(expected_user["id"]).to eq(user.id)
        expect(expected_user["name"]).to eq(user.name)
        expect(expected_user["email"]).to eq(user.email)
        expect(expected_user["email_verified"]).to eq(user.email_verified_at.present?)
        expect(expected_user["created_at"]).to be_present
        expect(expected_user).not_to have_key("pending_email")
        expect(expected_user).not_to have_key("password_digest")
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        get "/api/v1/users/me",
         headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/users/me",
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v1/users/me" do
    let(:user) { create(:user) }
    let(:name) { "Updated Name"}
    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when user is valid" do
      it "returns success" do
        patch "/api/v1/users/me",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "name": name
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expected_user = json["user"]
        expect(expected_user["id"]).to eq(user.id)
        expect(expected_user["name"]).to eq(name)
        expect(expected_user["name"]).to eq(user.reload.name)
        expect(expected_user["email"]).to eq(user.email)
        expect(expected_user["email_verified"]).to eq(user.email_verified_at.present?)
        expect(expected_user["created_at"]).to be_present
        expect(expected_user).not_to have_key("pending_email")
        expect(expected_user).not_to have_key("password_digest")
      end
    end
    
    context "when name with missing" do
      it "returns success" do
        original_name = user.name

        patch "/api/v1/users/me",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "name": nil
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(user.name).to eq(original_name)
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        patch "/api/v1/users/me",
          headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "name": name
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        patch "/api/v1/users/me",
        params: {
          "name": name
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/users/me/email_change" do
    let(:user) { create(:user) }
    let(:new_email) { "   new_email@test.in  " }

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when email change is requested with valid attributes" do
      it "returns success" do
        post "/api/v1/users/me/email_change",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "new_email": new_email
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        user.reload
        expect(user.pending_email).to eq("new_email@test.in")
        expect(user.email).not_to eq("new_email@test.in")
      end
    end
    
    context "when new email is missing" do
      it "returns success" do
        post "/api/v1/users/me/email_change",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "new_email": nil
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("New Email is required")
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        post "/api/v1/users/me/email_change",
          headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "new_email": new_email
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        post "/api/v1/users/me/email_change",
        params: {
          "new_email": new_email
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/users/me/email_verification" do
    let(:raw_token) { SecureRandom.urlsafe_base64(32) }

    let(:user) do
      token_digest = Digest::SHA256.hexdigest(raw_token)
      expires_at = 30.minutes.from_now

      create(:user, pending_email: "new_email@test.in", email_verification_token_digest: token_digest, email_verification_token_expires_at: expires_at)
    end

    let(:user_token) { JsonWebToken.encode({ user_id: user.id }) }

    context "when email is verified with valid attributes" do
      it "returns success" do
        post "/api/v1/users/me/email_verification",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "raw_token": raw_token
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expected_user = json["user"]
        expect(json["success"]).to eq(true)
        user.reload
        expect(user.pending_email).to be_nil
        expect(user.email).to eq("new_email@test.in")
        expect(expected_user["email_verified"]).to eq(true)
        expect(expected_user["email"]).to eq("new_email@test.in")
      end
    end
    
    context "when raw token is missing" do
      it "returns success" do
        post "/api/v1/users/me/email_verification",
        headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "raw_token": nil
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Raw token is required")
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        post "/api/v1/users/me/email_verification",
          headers: { 
          "Authorization" => "Bearer #{user_token}"
        },
        params: {
          "raw_token": raw_token
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        post "/api/v1/users/me/email_verification",
        params: {
          "raw_token": raw_token
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end