require 'rails_helper'

# 1. A membership with valid attributes is valid.
# 2. user association is required.
# 3. group association is required.
# 4. Role accepts only member or admin.
# 5. Status accepts only active or inactive.

RSpec.describe Membership, type: :model do
  it "is valid with valid attributes" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    membership = Membership.new(
      group: group, 
      user: user, 
      role: "member", 
      status: "active"
    )

    expect(membership).to be_valid
  end

  it "is invalid without a user" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    membership = Membership.new(
      group: group, 
      role: "member", 
      status: "active"
    )

    expect(membership).not_to be_valid
  end

  it "is invalid without a group" do
    user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    membership = Membership.new(
      user: user, 
      role: "member", 
      status: "active"
    )

    expect(membership).not_to be_valid
  end

  it "accepts valid roles" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    %w[member admin].each do |role|
      membership = Membership.new(
        group: group, 
        user: user, 
        role: role, 
        status: "active"
      )
      expect(membership).to be_valid
    end
  end

  it "accepts valid statuses" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    %w[active inactive].each do |status|
      membership = Membership.new(
        group: group, 
        user: user, 
        role: "member", 
        status: status
      )
      expect(membership).to be_valid
    end
  end

  it "rejects an invalid role" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    membership = Membership.new(
      group: group,
      user: user,
      role: "owner",
      status: "active"
    )

    expect(membership).not_to be_valid
  end

  it "rejects an invalid status" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    membership = Membership.new(
      group: group,
      user: user,
      role: "member",
      status: "pending"
    )

    expect(membership).not_to be_valid
  end
  
end
