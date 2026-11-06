require 'rails_helper'

RSpec.describe AuditTrail, type: :model do
  let(:user) do
    User.create!(
      name: "Neha",
      email: "neha@gmail.com",
      password: "password456"
    )
  end

  let(:audit_trail) do
    AuditTrail.new(
      user: user, 
      auditable: user, 
      action: "Test"
    )
  end

  it "is valid with valid attributes" do
    expect(audit_trail).to be_valid
  end

  it "is invalid without an auditable" do
    audit_trail.auditable = nil
    expect(audit_trail).not_to be_valid
  end

  it "is invalid without an action" do
    audit_trail.action = nil
    expect(audit_trail).not_to be_valid
  end

  it "is invalid with a blank action" do
    audit_trail.action = ""
    expect(audit_trail).not_to be_valid
  end
end
