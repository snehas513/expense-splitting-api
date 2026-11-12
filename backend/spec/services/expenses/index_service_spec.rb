require "rails_helper"

RSpec.describe Expenses::IndexService do
  let(:group) { create(:group) }
  let(:limit) { 20 }
  let(:cursor) { nil }
  let!(:expenses) do
    create_list(:expense, 25, group: group).each do |expense|
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

  let(:result) {
    described_class.new(
      group_id: group.id, 
      limit: limit, 
      cursor: cursor
    ).call
  }

  describe "#call" do
    context "when all attributes are valid" do
      
      it "list expenses" do
        expect(result[:success]).to be(true)
        expect(result[:expenses].map(&:group_id).uniq).to eq([group.id])
        expect(result[:expenses].count).to eq(20)
        expect(result[:expenses].pluck(:id)).to eq(result[:expenses].pluck(:id).sort.reverse)
        expect(result[:pagination][:has_more]).to be(true)
        expect(result[:pagination][:next_cursor]).to be_present
        expected_ids = expenses.map(&:id).sort.reverse.first(20)
        expect(result[:expenses].pluck(:id).first(20)).to eq(expected_ids)
      end
    end

    context "when fetching the next page" do
      it "returns the remaining expenses" do
        first_result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call

        second_result = described_class.new(
          group_id: group.id,
          limit: limit,
          cursor: first_result[:pagination][:next_cursor]
        ).call
      

        expect(second_result[:success]).to be(true)
        expect(second_result[:expenses].count).to eq(5)
        expect(second_result[:pagination][:has_more]).to be(false)
        expect(second_result[:pagination][:next_cursor]).to be_nil

        first_page_ids = first_result[:expenses].pluck(:id)
        second_page_ids = second_result[:expenses].pluck(:id)
        expect(second_page_ids & first_page_ids).to be_empty
      end
    end

    context "when expenses are fewer than limit records" do
      let!(:expenses) do
        create_list(:expense, 5, group: group).each do |expense|
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

      it "returns fewer than limit records" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(true)
        expect(result[:expenses].count).to eq(5)
        expect(result[:pagination][:has_more]).to be(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end
    end

    context "when expenses are exactly limit records" do
      let!(:expenses) do
        create_list(:expense, 5, group: group).each do |expense|
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

      let(:limit) { 5 }

      it "returns exactly limit records" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(true)
        expect(result[:expenses].count).to eq(5)
        expect(result[:pagination][:has_more]).to be(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end
    end

    context "when there are no expenses for an active group" do
      let!(:expenses) { nil }

      it "returns an empty result" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(true)
        expect(result[:expenses]).to be_empty
        expect(result[:pagination][:has_more]).to be(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end
    end

    context "when group is archived" do
      let(:group) { create(:group, :archived) }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group must be active")
      end
    end

    context "when group does not exist" do
      let(:result) {
        described_class.new(
          group_id: -1, 
          limit: limit, 
          cursor: cursor
        ).call
      }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when group_id is nil" do
      let(:result) {
        described_class.new(
          group_id: nil, 
          limit: limit, 
          cursor: cursor
        ).call
      }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when limit is nil" do
      let(:result) {
        described_class.new(
          group_id: group.id, 
          limit: nil, 
          cursor: cursor
        ).call
      }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Limit is required")
      end
    end

    context "when limit is zero" do
      let(:limit) { 0 }

      it "returns an error" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Limit must be a positive integer")
      end
    end

    context "when limit is greater than 100" do
      let(:limit) { 101 }

      it "returns an error" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Limit exceeds the maximum allowed value 100")
      end
    end

    context "when limit is non-numeric" do
      let(:limit) { "abc" }

      it "returns an error" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Limit must be a valid integer")
      end
    end

    context "when cursor is malformed" do
      let(:cursor) { "invalid-cursor" }
      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Cursor data is malformed")
      end
    end

    context "when expenses are inactive" do
      let!(:expenses) do
        create_list(:expense, 5, :deleted, group: group).each do |expense|
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

      let(:limit) { 5 }

      it "returns empty result" do
        result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call
      
        expect(result[:success]).to be(true)
        expect(result[:expenses]).to be_empty
        expect(result[:pagination][:has_more]).to be(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end
    end

    context "when multiple expenses have the same expense date" do
      let!(:expenses) do
        create_list(:expense, 15, group: group).each do |expense|
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

      let(:limit) { 10 }

      it "paginates expenses correctly without skipping or duplicating records" do
        first_result = described_class.new(
          group_id: group.id,
          limit: limit
        ).call

        second_result = described_class.new(
          group_id: group.id,
          limit: limit,
          cursor: first_result[:pagination][:next_cursor]
        ).call
      
        first_expected_ids = expenses.map(&:id).sort.reverse.first(10)
        expect(first_result[:expenses].pluck(:id)).to eq(first_expected_ids)

        second_expected_ids = expenses.map(&:id).sort.reverse.last(5)
        expect(second_result[:expenses].count).to eq(5)
        expect(second_result[:expenses].pluck(:id)).to eq(second_expected_ids)
        expect(second_result[:pagination][:has_more]).to be(false)
        expect(second_result[:pagination][:next_cursor]).to be_nil
      end
    end

  end
end