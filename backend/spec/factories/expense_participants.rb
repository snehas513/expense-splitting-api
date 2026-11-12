FactoryBot.define do
  factory :expense_participant do
    association :expense
    association :user
    share_amount { 600 }
  end
end