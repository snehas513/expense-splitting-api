FactoryBot.define do
  factory :settlement do
    association :group
    association :sender, factory: :user
    association :receiver, factory: :user
    association :creator, factory: :user
    settlement_amount { 1200 }
    status { "pending" }
    settlement_date { Date.current }

    trait :confirmed do
      status { "confirmed" }
    end
  end
end