class Users::LoginService
  attr_reader :email, :password, :user

  def initialize(email:, password:)
    @email = email&.strip&.downcase
    @password = password
    @errors = []
  end

  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    
    generate_jwt
    { success: true, user: @user.profile_json, auth_token: @token }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    fetch_user

    if user&.authenticate(password)
      # Password is correct
    else
      @errors << "Invalid email or password"
      return
    end

    if user.email_verified_at.blank?
      @errors << "Please verify your email before logging in"
    elsif !user.active?
      @errors << "Your account is deactivated"
    end
  end

  def fetch_user
    @user = User.find_by(email: email)
  end

  def generate_jwt
    @token = JsonWebToken.encode({ user_id: user.id }, 1.hour.from_now)
  end
end