require "rails_helper"

RSpec.describe Balances::PairwiseService do
  let(:group) { create(:group) }
  let(:participant_a) { create(:user) }
  let(:participant_b) { create(:user) }
  let(:participant_c) { create(:user) }

  let(:result) {
    described_class.new(
      group: group,
      sender: participant_c,
      receiver: participant_a
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
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

      it "calculates outstanding_debt between sender and receiver" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("200.00"))
      end

    end

    context "when a confirmed settlement partially reduces the outstanding debt" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
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

      let!(:settlement) { 
        create(
          :settlement,
          :confirmed,
          group: group,
          sender: participant_c,
          receiver: participant_a,
          creator: participant_c,
          settlement_amount: 100
        )
      }

      it "subtracts confirmed settlements from outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("100.00"))
      end

    end

    context "when a pending settlement does not reduce the outstanding debt" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
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

      let!(:settlement) { 
        create(
          :settlement,
          group: group,
          sender: participant_c,
          receiver: participant_a,
          creator: participant_c,
          settlement_amount: 100
        )
      }

      it "does not subtract pending settlements from outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("200.00"))
      end

    end

    context "when a confirmed settlement exists from receiver to sender" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
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

      let!(:settlement) { 
        create(
          :settlement,
          :confirmed,
          group: group,
          sender: participant_a,
          receiver: participant_c,
          creator: participant_a,
          settlement_amount: 100
        )
      }

      it "adds confirmed settlements from receiver to sender to outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("300.00"))
      end

    end

    context "when confirmed settlements from the sender completely cover the debt" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
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

      let!(:settlement) { 
        create(
          :settlement,
          :confirmed,
          group: group,
          sender: participant_c,
          receiver: participant_a,
          creator: participant_c,
          settlement_amount: 200
        )
      }

      it "reduces outstanding debt to zero when fully settled" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("0.00"))
      end

    end

    context "when the confirmed settlement exceeds the outstanding debt" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
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

      let!(:settlement) { 
        create(
          :settlement,
          :confirmed,
          group: group,
          sender: participant_c,
          receiver: participant_a,
          creator: participant_c,
          settlement_amount: 250
        )
      }

      it "does not return negative debt when confirmed settlements exceed outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("0.00"))
      end

    end

    context "when there are no expenses and no settlements" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns zero outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("0.00"))
      end
    end

    context "when deleted expenses must not contribute to outstanding debt" do
      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end

      let!(:expense1) { create(:expense, :deleted, group: group, creator: participant_a, payer: participant_a, amount: 1500) }
      let!(:expense2) { create(:expense, group: group, creator: participant_a, payer: participant_a, amount: 900) }

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

      it "excludes deleted expenses from outstanding debt" do
        expect(result[:success]).to be(true)
        expect(result[:outstanding_debt]).to eq(BigDecimal("300.00"))
      end

    end

    context "when group is missing" do
      let(:group) { nil }
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when sender and receiver are the same user" do
      let(:result) {
        described_class.new(
          group: group,
          sender: participant_c,
          receiver: participant_c
        ).call
      }

      let!(:memberships) do
        [participant_a, participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Sender and receiver must be different users")
      end
    end

    context "when sender is not an active group member" do
      let!(:memberships) do
        [participant_a, participant_b].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Sender must have an active account and active membership in the group")
      end
    end

    context "when receiver is not an active group member" do
      let!(:memberships) do
        [participant_b, participant_c].map do |user|
          create(:membership, group: group, user: user)
        end
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Receiver must have an active account and active membership in the group")
      end
    end

    context "when sender has an inactive membership" do
      let!(:memberships) do
        [
          create(:membership, :inactive, group: group, user: participant_c),
          create(:membership, group: group, user: participant_a),
          create(:membership, group: group, user: participant_b)
        ]
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Sender must have an active account and active membership in the group")
      end
    end

    context "when receiver has an inactive membership" do
      let!(:memberships) do
        [
          create(:membership, group: group, user: participant_c),
          create(:membership, :inactive, group: group, user: participant_a),
          create(:membership, group: group, user: participant_b)
        ]
      end
      
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Receiver must have an active account and active membership in the group")
      end
    end
  end
end