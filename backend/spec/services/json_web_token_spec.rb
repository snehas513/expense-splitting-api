require "rails_helper"

RSpec.describe JsonWebToken do
  describe ".secret_key" do

    let(:credentials) { Rails.application.credentials }

    context "when secret is missing" do
      before do
        allow(credentials)
          .to receive(:jwt_secret)
          .and_return(nil)
        end
      
      it "returns an error" do
        expect { JsonWebToken.secret_key }.to raise_error(RuntimeError, "JWT secret is missing from Rails credentials")
      end
    end

    context "when secret is present" do
      
      it "returns the secret" do
        expect(JsonWebToken.secret_key).to eq(credentials.jwt_secret)
      end
    end
  end

  describe ".encode" do

    let(:payload) {{ user_id: 123 }}

    context "when payload is passed" do
      
      it "returns the jwt token" do
        token = JsonWebToken.encode(payload)

        expect(token).to be_a(String)
      end
    end

    context "when payload is empty" do
      let(:payload) { {} }
      
      it "raises an error" do
        expect { JsonWebToken.encode(payload) }.to raise_error(RuntimeError, "Payload is empty")
      end
    end
  end

  describe ".decode" do

    let(:token) { JsonWebToken.encode({ user_id: 123 }) }

    context "when a valid token is passed" do
      
      it "returns the payload" do
        payload = JsonWebToken.decode(token)

        expect(payload["user_id"]).to eq(123)
      end
    end

    context "when a token is expired" do
      let(:token) { JsonWebToken.encode({ user_id: 123 }, 1.hour.ago) }
      
      it "returns nil" do
        payload = JsonWebToken.decode(token)

        expect(payload).to be_nil
      end
    end

    context "when a token is malformed" do
      let(:token) { "invalid-token" }
      
      it "returns nil" do
        payload = JsonWebToken.decode(token)

        expect(payload).to be_nil
      end
    end
  end
end