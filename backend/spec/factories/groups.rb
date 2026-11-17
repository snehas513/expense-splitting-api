FactoryBot.define do
  factory :group do
    name { "Test Group #{SecureRandom.uuid}" }
    description {"Test Group"}
    status { "active" }

    trait :archived do
      status { "archived" }
    end
  end
end