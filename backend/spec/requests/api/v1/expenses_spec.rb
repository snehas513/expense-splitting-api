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
        shares = json.dig("expense", "participants").pluck("share_amount")
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

  describe "GET /api/v1/groups/:group_id/expenses" do
    let(:group) { create(:group) }
    let(:limit) { 2 }
    let(:cursor) { nil }
    let(:creator) { create(:user) }
    
    let!(:expenses) do
      create_list(:expense, 10, group: group).each do |expense|
        payer = expense.payer
        participant = create(:user)

        create(:expense_participant,
          expense: expense,
          user: payer,
          share_amount: 600
        )

        create(:expense_participant,
          expense: expense,
          user: participant,
          share_amount: 600
        )
      end
    end

    let(:creator_token) { JsonWebToken.encode({ user_id: creator.id }) }

    context "when an authenticated group member requests expenses" do
      let!(:membership) do
        create(:membership, group: group, user: creator)
      end

      it "returns expenses" do
        get "/api/v1/groups/#{group.id}/expenses?limit=#{limit}",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        response_expenses = json.dig("expenses")
        has_more = json.dig("pagination", "has_more")
        expect(response_expenses.count).to eq(2)
        expect(has_more).to eq(true)
        expect(response_expenses.map { |expense| expense["group"]["name"] }.uniq)
          .to eq([group.name])

        expense = response_expenses.first
        expected_expense = expenses.find { |e| e.id == expense["id"] }
        expect(expected_expense).to be_present
        expect(expense["id"]).to be_present
        expect(expense["amount"]).to eq("1200.00")
        expect(expense["description"]).to eq("Test Description")
        expect(expense["group"]["id"]).to eq(group.id)
        expect(expense["payer"]).to include(
          "id" => expected_expense.payer.id,
          "name" => expected_expense.payer.name
        )
        expect(expense["creator"]).to include(
          "id" => expected_expense.creator.id,
          "name" => expected_expense.creator.name
        )
        participant_users = expense["participants"].map { |p| p["user"] }
        expected_expense.participants.each do |user|
          expect(participant_users).to include(
            "id" => user.id,
            "name" => user.name
          )
        end

        shares = expense["participants"].pluck("share_amount")
        expected_share = BigDecimal(expected_expense.amount.to_s) /
                 expected_expense.expense_participants.count
        expect(shares.sum(&:to_d)).to eq(BigDecimal(expected_expense.amount.to_s))
        expect(shares.map(&:to_d)).to all(eq(BigDecimal(expected_share)))
      end
    end

    context "when an authenticated user has an inactive membership" do
      let!(:membership) do
        create(:membership, :inactive, group: group, user: creator)
      end

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/expenses?limit=#{limit}",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when an authenticated user has no membership" do

      it "returns forbidden" do
        get "/api/v1/groups/#{group.id}/expenses?limit=#{limit}",
        headers: { 
          "Authorization" => "Bearer #{creator_token}"
        },
        as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when there is no Authorization header" do

      it "returns unauthorized" do
        get "/api/v1/groups/#{group.id}/expenses?limit=#{limit}",
        as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end


  end

  
end