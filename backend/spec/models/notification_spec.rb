require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:user) do
    User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456"
    )
  end

  let(:notification) do
    Notification.new(
      user: user, 
      notification_type: "group_invitation", 
      message: "Test Notification Message", 
      read: false
    )
  end

  it "is valid with valid attributes" do
    expect(notification).to be_valid
  end

  it "is invalid without an user" do
    notification.user = nil
    expect(notification).not_to be_valid
  end

  it "is invalid without a notification_type" do
    notification.notification_type = nil
    expect(notification).not_to be_valid
  end

  it "is invalid without an message" do
    notification.message = nil
    expect(notification).not_to be_valid
  end

  it "allows valid notification types" do
    Notification::NOTIFICATION_TYPES.each do |notification_type|
      notification.notification_type = notification_type
      expect(notification).to be_valid
    end
  end

  it "is invalid when notification type is wrong" do
    notification.notification_type = "payment_received"
    expect(notification).not_to be_valid
  end

  it "allows valid read types" do
    [true, false].each do |type|
      notification.read = type
      expect(notification).to be_valid
    end
  end
end
