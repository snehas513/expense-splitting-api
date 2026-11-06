require 'rails_helper'

RSpec.describe Settlement, type: :model do
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

  let(:sender) { user }

  let(:receiver) do
    User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456"
    )
  end

  let(:acted_by) { user }

  let(:settlement) do
    Settlement.new(
      group: group, 
      sender: sender, 
      receiver: receiver, 
      settlement_amount: 2000, 
      status: "pending", 
      settlement_date: Date.current, 
      acted_by: acted_by
    )
  end

  it "is valid with valid attributes" do
    expect(settlement).to be_valid
  end

  it "is invalid without a group" do
    settlement.group = nil
    expect(settlement).not_to be_valid
  end

  it "is invalid without a sender" do
    settlement.sender = nil
    expect(settlement).not_to be_valid
  end

  it "is invalid without a receiver" do
    settlement.receiver = nil
    expect(settlement).not_to be_valid
  end

  it "is valid without an acted_by" do
    settlement.acted_by = nil
    expect(settlement).to be_valid
  end

  it "is invalid when settlement_amount is negative" do
    settlement.settlement_amount = -1
    expect(settlement).not_to be_valid
  end

  it "is invalid when settlement_amount is zero" do
    settlement.settlement_amount = 0
    expect(settlement).not_to be_valid
  end

  it "is invalid when settlement_date is missing" do
    settlement.settlement_date = nil
    expect(settlement).not_to be_valid
  end

  it "is valid when status is either of pending, confirmed, rejected, cancelled" do
    %w[pending confirmed rejected cancelled].each do |status|
      settlement.status = status
      expect(settlement).to be_valid
    end
  end

  it "is invalid when status is wrong" do
    settlement.status = "archived"
    expect(settlement).not_to be_valid
  end
end
