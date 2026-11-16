FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "user-#{SecureRandom.uuid}@example.com" }
    password { "password123" }
    status { "active" }

    trait :deactivated do
      status { "deactivated" }
    end
  end
end