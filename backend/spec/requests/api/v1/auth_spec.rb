require "rails_helper"

RSpec.describe "Users API", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:params) do
      {
        name: "Sneha",
        email: "sneha@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    context "when user attrinutes are valid" do
      it "returns success" do
        post "/api/v1/auth/register",
          params: params,
          as: :json

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Registration successful. Please verify your email.")
        expected_user = json["user"]
        expect(expected_user["id"]).to be_present
        expect(expected_user["name"]).to eq("Sneha")
        expect(expected_user["email"]).to eq("sneha@example.com")
        expect(expected_user).not_to have_key("password_digest")
      end
    end

    context "when registration fails" do
      let!(:user) { create(:user, email: "sneha@example.com")}

      it "returns validation errors without creating a user" do
        expect {
          post "/api/v1/auth/register",
              params: params,
              as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "POST /api/v1/auth/verify_email" do
    let(:raw_token) { SecureRandom.urlsafe_base64(32) }

    let!(:user) do
      token_digest = Digest::SHA256.hexdigest(raw_token)
      expires_at = 30.minutes.from_now

      create(:user, email: "email123@test.in", email_verification_token_digest: token_digest, email_verification_token_expires_at: expires_at)
    end

    context "when user is verified with valid attributes" do
      it "returns success" do
        post "/api/v1/auth/verify_email",
          params: {
            "raw_token": raw_token
          },
          as: :json
        
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Email verification successful. You can login.")
        user.reload
        expect(user.email_verified_at).to be_present
        expected_user = json["user"]
        expect(expected_user["id"]).to be_present
        expect(expected_user["email"]).to eq("email123@test.in")
        expect(expected_user).not_to have_key("password_digest")
      end
    end
    
    context "when raw token is missing" do
      it "returns unprocessable_entity" do
        post "/api/v1/auth/verify_email",
        params: {
          "raw_token": nil
        },
        as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Invalid or expired verification token")
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }

      it "returns unauthorized" do
        post "/api/v1/auth/verify_email",
          params: {
            "raw_token": raw_token
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "sneha@example.com", password: "password123", email_verified_at: Time.current) }
    
    let(:params) do
      {
        email: "sneha@example.com",
        password: "password123"
      }
    end

    context "when login is successful" do

      it "returns jwt" do
        post "/api/v1/auth/login",
          params: params,
          as: :json
        
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["success"]).to be(true)
        user.reload
        expect(json["auth_token"]).to be_present
        decoded = JsonWebToken.decode(json["auth_token"])
        expect(decoded["user_id"]).to eq(user.id)
        expect(json["user"]["email"]).to eq(user.email)
        expect(json["user"]["email_verified"]).to be(true)
      end
    end
    
    context "when email is incorrect" do
      it "returns unauthorized" do
        post "/api/v1/auth/login",
        params: {
          email: "sneha@example.com",
          password: "password1234"
        },
        as: :json

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Invalid email or password"
        )
      end
    end

    context "when user is deactivated" do
      before do
        user.update!(status: "deactivated")
      end

      it "returns unauthorized" do
        post "/api/v1/auth/login",
          params: params,
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end