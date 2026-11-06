require 'rails_helper'

RSpec.describe ExpenseParticipant, type: :model do
  let(:user) do
    User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456"
    )
  end

  let(:group) do
    Group.create!(name: "Test Group", status: "active")
  end

  let(:payer) { user }

  let(:creator) { user }

  let(:expense) do
    Expense.new(
      group: group,
      payer: payer,
      creator: creator,
      amount: 2000,
      description: "Test Expense",
      status: "active",
      expense_date: Date.current
    )
  end

  let(:expense_participant) do
    ExpenseParticipant.new(
      expense: expense, 
      user: user, 
      share_amount: 200.05
    )
  end

  it "is valid with valid attributes" do
    expect(expense_participant).to be_valid
  end

  it "is invalid without an expense" do
    expense_participant.expense = nil
    expect(expense_participant).not_to be_valid
  end

  it "is invalid without a user" do
    expense_participant.user = nil
    expect(expense_participant).not_to be_valid
  end

  it "is invalid when share_amount is negative" do
    expense_participant.share_amount = -1
    expect(expense_participant).not_to be_valid
  end

  it "is invalid when share_amount is zero" do
    expense_participant.share_amount = 0
    expect(expense_participant).not_to be_valid
  end
end
