require "rails_helper"

RSpec.describe Authenticatable, type: :request do
  describe "GET /authentication_test" do
    context "when authorization header is missing" do
      it "returns unauthorized" do
        get "/authentication_test"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorization header is valid" do
      let(:user) { create(:user) }
      let(:token) { JsonWebToken.encode({ user_id: user.id }) }

      it "returns success" do
        get "/authentication_test",
          headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when token is expired" do
      let(:user) { create(:user) }
      let(:token) { JsonWebToken.encode({ user_id: user.id  }, 1.hour.ago) }

      it "returns unauthorized" do
        get "/authentication_test",
          headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is deactivated" do
      let(:user) { create(:user, :deactivated) }
      let(:token) { JsonWebToken.encode({ user_id: user.id  }) }

      it "returns unauthorized" do
        get "/authentication_test",
          headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user that doesn't exist" do
      let(:token) { JsonWebToken.encode({ user_id: 123  }) }

      it "returns unauthorized" do
        get "/authentication_test",
          headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end