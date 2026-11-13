require "rails_helper"

RSpec.describe Balances::Serializer do
  describe "#call" do
    let(:user1) { create(:user, name: "Sneha") }
    let(:user2) { create(:user, name: "Neha") }
    let(:user3) { create(:user, name: "Rahul") }

    let(:balances_hash) do
      {
        user1.id => BigDecimal("6000.00"),
        user2.id => BigDecimal("-2500.50"),
        user3.id => BigDecimal("0.00")
      }
    end

    subject(:result) do
      described_class.new(balances_hash: balances_hash).call
    end

    context "when balance is positive" do
      
      it "returns balance as a string formatted to two decimal places" do
        expect(result[:balances].first[:balance]).to eq("6000.00")
        expect(result[:balances].first[:balance]).to be_a(String)
        expect(result[:balances].size).to eq(3)
        expect(result[:balances].first).to eq(
          user_id: user1.id,
          name: "Sneha",
          balance: "6000.00"
        )
      end
    end

    context "when balance is negative" do
      it "preserves the negative sign and formats to two decimal places" do
        expect(result[:balances].second[:balance]).to eq("-2500.50")
      end
    end

    context "when balance is zero" do
      it "formats zero balance as 0.00" do
        expect(result[:balances].third[:balance]).to eq("0.00")
      end
    end

    context "when balances are empty" do
      let(:balances_hash) { {} }

      it "returns an empty balances array" do
        expect(result[:balances]).to eq([])
      end
    end
  end
end