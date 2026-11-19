class Users::VerifyEmailService
  attr_reader :user, :raw_token

  def initialize(user:, raw_token:)
    @user = user
    @raw_token = raw_token
    @errors = []
  end

  def call
    return { success: false, errors: ["User is required"] } if user.blank?

    user.with_lock do
      validate
      return { success: false, errors: @errors } unless @errors.empty?

      update_email
    end
    send_email
    { success: true, user: user.profile_json }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_user
    validate_raw_token if @errors.empty?
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
  end

  def validate_raw_token
    if raw_token.blank?
      @errors << "Raw token is required"
      return
    end

    if user.email_verification_token_digest.blank? ||
        user.email_verification_token_expires_at.blank? ||
        user.pending_email.blank?
      @errors << "Raw token is invalid"
      return
    end

    if user.email_verification_token_expires_at <= Time.current
      @errors << "Verification token has expired"
      return
    end

    token_digest = Digest::SHA256.hexdigest(raw_token)

    unless ActiveSupport::SecurityUtils.secure_compare(
            token_digest,
            user.email_verification_token_digest
          )
      @errors << "Raw token is invalid"
    end
  end

  def update_email
    user.update!(
      email: user.pending_email,
      pending_email: nil,
      email_verified_at: Time.current,
      email_verification_token_digest: nil,
      email_verification_token_expires_at: nil
    )
  end

  def send_email
    UserMailer.email_change_confirmation(
      user: user
    ).deliver_later
  end
end