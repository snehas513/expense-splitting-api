FactoryBot.define do
  factory :membership do
    association :group
    association :user
    role { "member" }
    status { "active" }

    trait :inactive do
      status { "inactive" }
    end
  end
end