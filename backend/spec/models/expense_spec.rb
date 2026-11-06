require 'rails_helper'

# 1. Valid expense attributes.
# 2. Group association required.
# 3. Payer association required.
# 4. Creator association required.
# 5. Description required.
# 6. Expense date required.
# 7. Amount must be greater than zero.
# 8. Amount is negative
# 9. Status must be active or deleted.
# 10. Invalid status

RSpec.describe Expense, type: :model do
  let(:group) do
    Group.create!(name: "Test Group", status: "active")
  end

  let(:payer) do
    User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456"
    )
  end

  let(:creator) do
    User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456"
    )
  end

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

  it "is valid with valid attributes" do
    expect(expense).to be_valid
  end

  it "is invalid without a group" do
    expense.group = nil
    expect(expense).not_to be_valid
  end

  it "is invalid without a payer" do
    expense.payer = nil
    expect(expense).not_to be_valid
  end

  it "is invalid without a creator" do
    expense.creator = nil
    expect(expense).not_to be_valid
  end

  it "is invalid without a description" do
    expense.description = nil
    expect(expense).not_to be_valid
  end

  it "is invalid without an expense date" do
    expense.expense_date = nil
    expect(expense).not_to be_valid
  end

  it "is invalid when amount is zero" do
    expense.amount = 0
    expect(expense).not_to be_valid
  end

  it "is invalid when amount is negative" do
    expense.amount = -1000
    expect(expense).not_to be_valid
  end

  it "is valid when status is active" do
    expense.status = "active"
    expect(expense).to be_valid
  end

  it "is valid when status is deleted" do
    expense.status = "deleted"
    expect(expense).to be_valid
  end

  it "is invalid when status is not active or deleted" do
    expense.status = "restored"
    expect(expense).not_to be_valid
  end 
  
end
