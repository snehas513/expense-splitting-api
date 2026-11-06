require 'rails_helper'

# 1. A group with valid attributes is valid.
# 2. Name cannot be blank.
# 3. Status must be one of active, archived, or deleted.
# 4. An invalid status is rejected.

RSpec.describe Group, type: :model do
  it "is valid with valid attributes" do
    group = Group.new(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    expect(group).to be_valid
  end

  it "is invalid without a name" do
    group = Group.new(
      description: "Test Group", 
      status: "active"
    )

    expect(group).not_to be_valid
  end

  it "accepts all allowed statuses" do
    %w[active archived deleted].each do |status|
      group = Group.new(name: "Test Group", status: status)
      expect(group).to be_valid
    end
  end

  it "rejects invalid status" do
    group = Group.new(name: "Test Group", status: "pending")
    expect(group).not_to be_valid
  end
end
