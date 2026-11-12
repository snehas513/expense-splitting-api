require "rails_helper"

RSpec.describe "Expenses API", type: :request do
  describe "POST /api/v1/groups/:group_id/expenses" do
    let(:group) { create(:group) }
    let(:creator) { create(:user) }
    let(:payer) { create(:user) }
    let(:participant1) { create(:user) }
    let(:amount) { 1000 }
    let(:description) { "Dinner" }
    let(:expense_date) { Date.current }
    let(:note) { "Team dinner" }

    let(:creator_token) { JsonWebToken.encode({ user_id: creator.id }) }

    context "creates an expense with two participants successfully" do
      let!(:memberships) do
        [creator, payer, participant1].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      it "returns success" do
        expect {
          post "/api/v1/groups/#{group.id}/expenses",
          headers: { 
            "Authorization" => "Bearer #{creator_token}"
          },
          params: {
            "payer_id": payer.id,
            "participant_ids": [payer.id, participant1.id],
            "amount": amount,
            "description": description,
            "expense_date": expense_date,
            "note": note
          },
          as: :json
        }.to change(Expense, :count).by(1)
          .and change(ExpenseParticipant, :count).by(2)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        shares = json.dig("expense", "expense_participants").pluck("share_amount")
        expect(shares.sum(&:to_d)).to eq(BigDecimal(amount.to_s))

        expense_amount = json.dig("expense", "amount")
        expect(expense_amount.to_d).to eq(BigDecimal(amount.to_s))

        expect(shares.map(&:to_d)).to all(eq(BigDecimal("500")))

        expense_description = json.dig("expense", "description")
        expect(expense_description).to eq(description)
      end
    end

    context "when the group does not exist" do

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/-1/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)        
      end
    end

    context "when the payer does not exist" do

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: -1,
            participant_ids: [participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when one of the participants does not exist" do

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, -1],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:not_found)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when participant_ids are missing" do

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: nil,
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:bad_request)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when participant_ids is not an array" do

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: "1,2",
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:bad_request)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when creator is not an active member of the group" do
      let!(:memberships) do
        [
          create(:membership, :inactive, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, group: group, user: participant1)
        ]
      end

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when payer is not an active member of the group" do
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, :inactive, group: group, user: payer),
          create(:membership, group: group, user: participant1)
        ]
      end

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when payer account is deactivated" do
      let(:payer) { create(:user, :deactivated) }
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, group: group, user: participant1)
        ]
      end

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when one of the participants has a deactivated account" do
      let(:participant1) { create(:user, :deactivated) }
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, group: group, user: participant1)
        ]
      end

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end

    context "when one of the participant is not an active member of the group" do
      let!(:memberships) do
        [
          create(:membership, group: group, user: creator),
          create(:membership, group: group, user: payer),
          create(:membership, :inactive, group: group, user: participant1)
        ]
      end

      it "returns an error" do
        expenses_before = Expense.count
        participants_before = ExpenseParticipant.count

        post "/api/v1/groups/#{group.id}/expenses",
          headers: { "Authorization" => "Bearer #{creator_token}" },
          params: {
            payer_id: payer.id,
            participant_ids: [payer.id, participant1.id],
            amount: amount,
            description: description,
            expense_date: expense_date,
            note: note
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Expense.count).to eq(expenses_before)
        expect(ExpenseParticipant.count).to eq(participants_before)
      end
    end
  end
end