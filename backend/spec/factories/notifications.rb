FactoryBot.define do
  factory :notification do
    association :user
    message { "Test Notifications #{SecureRandom.uuid}" }
    notification_type { "group_invitation" }
    read { false }
  end
end