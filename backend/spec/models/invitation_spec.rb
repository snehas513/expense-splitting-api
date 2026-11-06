require 'rails_helper'

# Valid invitation attributes.
# Group association is required.
# Invited user association is required.
# Invited by association is required.
# sent_at is required.
# Status accepts pending, accepted, rejected, and revoked.
# Invalid status is rejected.
    
RSpec.describe Invitation, type: :model do
  it "is valid with valid attributes" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    invited_user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invited_by = User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invitation = Invitation.new(
      group: group, 
      invited_user: invited_user, 
      invited_by: invited_by, 
      status: "pending", 
      sent_at: Time.current
    )

    expect(invitation).to be_valid
  end

  it "is invalid without an invited user" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    invited_by = User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invitation = Invitation.new(
      group: group, 
      invited_by: invited_by, 
      status: "pending", 
      sent_at: Time.current
    )

    expect(invitation).not_to be_valid
  end

  it "is invalid without an inviter" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    invited_user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invitation = Invitation.new(
      group: group, 
      invited_user: invited_user, 
      status: "pending", 
      sent_at: Time.current
    )

    expect(invitation).not_to be_valid
  end

  it "is invalid without a group" do
    invited_user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invited_by = User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invitation = Invitation.new(
      invited_user: invited_user, 
      invited_by: invited_by, 
      status: "pending", 
      sent_at: Time.current
    )

    expect(invitation).not_to be_valid
  end

  it "is invalid without sent_at" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    invited_user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invited_by = User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invitation = Invitation.new(
      group: group, 
      invited_user: invited_user, 
      invited_by: invited_by, 
      status: "pending" 
    )

    expect(invitation).not_to be_valid
  end

  it "rejects an invalid status" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    invited_user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invited_by = User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invitation = Invitation.new(
      group: group, 
      invited_user: invited_user, 
      invited_by: invited_by, 
      status: "active",
      sent_at: Time.current 
    )

    expect(invitation).not_to be_valid
  end

  it "accepts valid statuses" do
    group = Group.create!(
      name: "Test Group", 
      description: "Test Group", 
      status: "active"
    )

    invited_user = User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    invited_by = User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    %w[pending accepted rejected revoked].each do |status|
      invitation = Invitation.new(
        group: group, 
        invited_user: invited_user, 
        invited_by: invited_by,
        sent_at: Time.current, 
        status: status 
      )

      expect(invitation).to be_valid
    end

    
  end
end
