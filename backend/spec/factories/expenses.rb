FactoryBot.define do
  factory :expense do
    association :group
    association :payer, factory: :user
    association :creator, factory: :user
    amount { 1200 }
    description { "Test Description" }
    note { "Test Note" }
    status { "active" }
    expense_date { Date.current }

    trait :deleted do
      status { "deleted" }
    end
  end
end