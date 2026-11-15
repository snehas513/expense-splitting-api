require "rails_helper"

RSpec.describe "Settlements API", type: :request do
  describe "POST /api/v1/groups/:group_id/settlements" do
    let(:group) { create(:group) }

    let(:participant_a) { create(:user) }
    let(:participant_b) { create(:user) }
    let(:participant_c) { create(:user) }

    let(:sender) { participant_c }
    let(:creator) { participant_c }
    let(:receiver) { participant_a }

    let(:settlement_amount) { 100 }
    let(:settlement_date) { Date.current }
    let(:note) { "Settled ₹#{settlement_amount}" }

    let(:creator_token) { JsonWebToken.encode({ user_id: creator.id }) }

    context "creates a settlement successfully" do
      let!(:memberships) do
        [sender, receiver].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: participant_c, payer: participant_c, amount: 900) }

      let!(:expense_participant_for_expense1) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense1,
            user: user,
            share_amount: 500
          )
        end
      end

      let!(:expense_participant_for_expense2) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:expense_participant,
            expense: expense2,
            user: user,
            share_amount: 300
          )
        end
      end

      it "creates a pending settlement and returns its details" do
        expect {
          post "/api/v1/groups/#{group.id}/settlements",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "sender_id": sender.id,
            "receiver_id": receiver.id,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json
        }.to change(Settlement, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
      
        expected_settlement = json["settlement"]
        expect(json["success"]).to be(true)
        expect(expected_settlement["settlement_amount"].to_d).to eq(BigDecimal(settlement_amount.to_s))
        expect(expected_settlement["note"]).to eq(note)
        expect(expected_settlement["group"]["id"]).to eq(group.id)
        expect(expected_settlement["sender"]).to include(
          "id" => sender.id,
          "name" => sender.name
        )
        expect(expected_settlement["receiver"]).to include(
          "id" => receiver.id,
          "name" => receiver.name
        )
        expect(expected_settlement["creator"]).to include(
          "id" => creator.id,
          "name" => creator.name
        )
        expect(expected_settlement["status"]).to eq("pending")
        expect(expected_settlement["acted_by"]).to be_nil
      end
    end

    context "when the group does not exist" do

      it "returns not_found" do
        settlements_before = Settlement.count

        post "/api/v1/groups/#{-1}/settlements",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "sender_id": sender.id,
            "receiver_id": receiver.id,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Settlement.count).to eq(settlements_before)
      end
    end

    context "when the receiver does not exist" do

      it "returns not_found" do
        settlements_before = Settlement.count

        post "/api/v1/groups/#{group.id}/settlements",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "sender_id": sender.id,
            "receiver_id": -1,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Settlement.count).to eq(settlements_before)
      end
    end

    context "when the sender does not exist" do

      it "returns not_found" do
        settlements_before = Settlement.count

        post "/api/v1/groups/#{group.id}/settlements",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "sender_id": -1,
            "receiver_id": receiver.id,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Settlement.count).to eq(settlements_before)
      end
    end

    context "when there is no authorization header" do

      it "returns unauthorized" do
        settlements_before = Settlement.count

        post "/api/v1/groups/#{group.id}/settlements",
          params: {
            "sender_id": -1,
            "receiver_id": receiver.id,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Settlement.count).to eq(settlements_before)
      end
    end

    context "when the creator is neither sender nor receiver" do
      let(:creator) { create(:user) }
      let(:creator_token) { JsonWebToken.encode({ user_id: creator.id }) }

      it "returns unprocessable_entity" do
        settlements_before = Settlement.count

        post "/api/v1/groups/#{group.id}/settlements",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "sender_id": sender.id,
            "receiver_id": receiver.id,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(Settlement.count).to eq(settlements_before)
        expect(json["errors"]).to include(
          "Creator must be either the sender or receiver"
        )
      end
    end

    context "when the settlement amount is invalid" do
          let(:settlement_amount) { "invalid" }

      it "returns unprocessable_entity" do
        settlements_before = Settlement.count

        post "/api/v1/groups/#{group.id}/settlements",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "sender_id": sender.id,
            "receiver_id": receiver.id,
            "settlement_amount": settlement_amount,
            "settlement_date": settlement_date,
            "note": note
          },
          as: :json

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(Settlement.count).to eq(settlements_before)
        expect(json["errors"]).to include(
          "Settlement Amount must be a valid number"
        )
      end
    end
  end
end