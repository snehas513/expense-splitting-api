require "rails_helper"

RSpec.describe Settlements::CreateService do
  # self.use_transactional_tests = false

  let!(:group) { create(:group) }
  let!(:sender) { create(:user, email: "sender-#{SecureRandom.uuid}@example.com") }
  let!(:receiver) { create(:user, email: "receiver-#{SecureRandom.uuid}@example.com") }
  let!(:creator) { receiver }

  let!(:memberships) do
    [sender, receiver].map do |user|
      create(:membership, group: group, user: user)
    end
  end

  let!(:expense) { create(:expense, group: group, creator: receiver, payer: receiver, amount: 1000) }

  let!(:expense_participant) do
    [sender, receiver].map do |user|
      create(:expense_participant,
        expense: expense,
        user: user,
        share_amount: 500
      )
    end
  end

  after do
    SettlementExpense.where(
      settlement_id: Settlement.where(group_id: group.id).select(:id)
    ).delete_all

    Settlement.where(group_id: group.id).delete_all
    ExpenseParticipant.where(expense_id: expense.id).delete_all
    Expense.where(id: expense.id).delete_all
    Membership.where(group_id: group.id).delete_all
    Group.where(id: group.id).delete_all
    User.where(id: [sender.id, receiver.id, creator.id]).delete_all
  end

  it "prevents concurrent settlements from over-allocating an expense" do
    # - ready: confirms both threads have a database connection and are ready.
    # - start: releases both threads to execute together.
    # - results: collects each service response.

    ready = Queue.new
    start = Queue.new
    results = Queue.new

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop

          group_record = Group.find(group.id)
          sender_record = User.find(sender.id)
          receiver_record = User.find(receiver.id)
          creator_record = User.find(creator.id)

          result = Settlements::CreateService.new(
            group: group_record,
            sender: sender_record,
            receiver: receiver_record,
            creator: creator_record,
            settlement_amount: 300,
            settlement_date: Date.current,
            allocations: [
              { expense_id: expense.id, allocation_amount: 300 }
            ]
          ).call

          results << result
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }

    threads.each(&:value)

    responses = 2.times.map { results.pop }

    expect(responses.count { |response| response[:success] }).to eq(1)
    expect(responses.count { |response| !response[:success] }).to eq(1)

    expect(
      expense.settlement_expenses.joins(:settlement)
        .where(settlements: { status: %w[pending confirmed] })
        .sum(:allocation_amount)
    ).to eq(300)
  end

end