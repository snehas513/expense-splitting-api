class Users::RequestRegistrationVerificationService
  include EmailVerificationToken

  attr_reader :user

  def initialize(user:)
    @user = user
    @errors = []
  end

  def call
    return { success: false, errors: ["User is required"] } if user.blank?

    user.with_lock do
      validate_user
      return { success: false, errors: @errors } unless @errors.empty?

      generate_verification_token
      store_verification_token
    end

    send_email
    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate_user
    if !user.active?
      @errors << "User must have an active account"
    elsif user.email_verified_at.present?
      @errors << "Email is already verified"
    end
  end

  def store_verification_token
    user.update!(
      email_verification_token_digest: token_digest,
      email_verification_token_expires_at: token_expires_at
    )
  end

  def send_email
    UserMailer.email_verification(
      user: user,
      raw_token: raw_token,
      purpose: :registration
    ).deliver_later
  end
end