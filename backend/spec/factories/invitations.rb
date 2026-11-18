FactoryBot.define do
  factory :invitation do
    association :group
    association :invited_by, factory: :user
    association :invited_user, factory: :user
    status { "pending" }
    sent_at { Time.current }

    after(:create) do |invitation|
      create(:membership,
        group: invitation.group,
        user: invitation.invited_by,
        status: "active"
      ) unless Membership.exists?(
        group: invitation.group,
        user: invitation.invited_by,
        status: "active"
      )
    end
  end
end