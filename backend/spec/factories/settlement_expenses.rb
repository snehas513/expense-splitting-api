FactoryBot.define do
  factory :settlement_expense do
    association :settlement
    association :expense
    allocation_amount { 100.00 }
  end
end