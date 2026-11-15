require "rails_helper"

RSpec.describe Settlements::ConfirmService do
  let(:group) { create(:group) }

  let(:participant_a) { create(:user) }
  let(:participant_b) { create(:user) }
  let(:participant_c) { create(:user) }

  let(:sender) { participant_c }
  let(:creator) { participant_c }
  let(:receiver) { participant_a }
  let(:acted_by) { receiver }

  let(:settlement) {
                      create(
                      :settlement,
                      group: group,
                      sender: sender,
                      receiver: receiver,
                      creator: creator,
                      settlement_amount: 1000
                    )
                  }

  let(:result) {
    described_class.new(
      group: group,
      settlement: settlement,
      acted_by: acted_by
    ).call
  }

  describe "#call" do
    let!(:memberships) do
      [participant_a, participant_b, participant_c].map do |user|
        create(:membership, group: group, user: user)
      end
    end

    context "when all attributes are valid" do
      
      it "confirms the settlement" do
        expect(result[:success]).to be(true)
        expect(result[:settlement].reload.status).to eq("confirmed")
        expect(result[:settlement].acted_by).to eq(acted_by)
      end
    end

    context "when the creator wants to confirm the settlement" do
      let(:result) {
        described_class.new(
          group: group,
          settlement: settlement,
          acted_by: creator
        ).call
      }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Creator and Acted By must be different users"
        )
        expect(settlement.reload.status).to eq("pending")
        expect(settlement.acted_by).to be_nil
      end
    end

    context "when an unrelated user wants to confirm" do
      let(:result) {
        described_class.new(
          group: group,
          settlement: settlement,
          acted_by: participant_b
        ).call
      }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Acted By must be either the sender or receiver"
        )
        expect(settlement.reload.status).to eq("pending")
        expect(settlement.acted_by).to be_nil
      end
    end

    context "when an already-confirmed settlement is requested for confirmation" do
      let(:settlement) {
                      create(
                      :settlement,
                      :confirmed,
                      group: group,
                      sender: sender,
                      receiver: receiver,
                      creator: creator,
                      settlement_amount: 1000
                    )
                  }

      let(:result) {
        described_class.new(
          group: group,
          settlement: settlement,
          acted_by: acted_by
        ).call
      }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Settlement must be pending"
        )
        expect(settlement.acted_by).to be_nil
      end
    end

    context "when a settlement is missing" do
      let(:settlement) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "Settlement is required"
        )
      end
    end
  end
end