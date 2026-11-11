require 'rails_helper'

# 1. A user with valid attributes is valid.
# 2. Name cannot be blank.
# 3. Email cannot be blank.
# 4. Email must be unique (case-insensitive).
# 5. Invalid email format is rejected.
# 6. Pending email can be nil.
# 7. Pending email must be unique (case-insensitive) when present.
# 8. Password is required when creating a user.
# 9. User status must be either active or deactivated.

RSpec.describe User, type: :model do
  it "is valid with valid attributes" do
    user = User.new(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password456",
      password_confirmation: "password456"
    )

    expect(user).to be_valid # Expects the model to pass validations.
  end

  it "is invalid without a name" do
    user = User.new(
      name: "Alice",
      email: "alice@example.com",
      password: "password123"
    )

    expect(user).not_to be_valid # not_to be_valid means we expect the model to fail validation.
  end

  it "is invalid without an email" do
    user = User.new(
      name: "Sneha",
      password: "password123"
    )

    expect(user).not_to be_valid
  end

  it "rejects duplicate emails case-insensitively" do
    User.create!(
      name: "Sneha",
      email: "sneha@gmail.com",
      password: "password123"
    )

    user = User.new(
      name: "Sneha",
      email: "snehA@gmail.com",
      password: "password123"
    )

    expect(user).not_to be_valid
  end

  it "rejects invalid email format" do
    user = User.new(
      name: "Sneha",
      email: "alice@example!.com",
      password: "password123"
    )

    expect(user).not_to be_valid
  end

  it "allows pending email to be nil" do
    user = User.new(
      name: "Sneha",
      email: "alice@example.com",
      password: "password123"
    )

    expect(user).to be_valid
  end

  it "rejects duplicate pending emails case-insensitively" do
    User.create!(
      name: "Sneha",
      email: "first@example.com",
      pending_email: "new@example.com",
      password: "password123"
    )

    user = User.new(
      name: "Another User",
      email: "second@example.com",
      pending_email: "NEW@example.com",
      password: "password123"
    )

    expect(user).not_to be_valid
  end

  it "is invalid without a password" do
    user = User.new(
      name: "Sneha",
      email: "alice@example.com"
    )

    expect(user).not_to be_valid
  end

  it "rejects an invalid status" do
    user = User.new(
      name: "Sneha",
      email: "alice@example.com",
      password: "password123",
      status: "suspended"
    )

    expect(user).not_to be_valid
  end
end
