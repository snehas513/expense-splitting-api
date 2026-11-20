class Users::RegisterService
  attr_reader :name, :email, :password, :password_confirmation

  def initialize(name:, email:, password:, password_confirmation:)
    @name = name
    @email = email
    @password = password
    @password_confirmation = password_confirmation
  end

  def call
    create_user

    { success: true, user: @user }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def create_user
    @user = User.create!(
      name: name,
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      status: "active",
      email_verified_at: nil
    )
  end
end