FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    status { "active" }

    trait :deactivated do
      status { "deactivated" }
    end
  end
end