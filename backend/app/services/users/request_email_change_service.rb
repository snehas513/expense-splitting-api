class Users::RequestEmailChangeService
  include EmailVerificationToken

  attr_reader :user, :new_email

  def initialize(user:, new_email:)
    @user = user
    @new_email = new_email&.strip&.downcase
    @errors = []
  end

  def call
    return { success: false, errors: ["User is required"] } if user.blank?

    user.with_lock do
      validate
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

  def validate
    validate_user
    validate_new_email if @errors.empty?
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
  end

  def validate_new_email
    if new_email.blank?
      @errors << "New Email is required"
    elsif !URI::MailTo::EMAIL_REGEXP.match?(new_email)
      @errors << "Invalid email format"
    elsif new_email == user.email
      @errors << "New email must be different from current email"
    elsif User.where(email: new_email).where.not(id: user.id).exists? ||
        User.where(pending_email: new_email).where.not(id: user.id).exists?
      @errors << "Email has already been taken"
    end
  end

  def store_verification_token
    user.update!(
      email_verification_token_digest: token_digest, 
      email_verification_token_expires_at: token_expires_at, 
      pending_email: new_email
    )
  end

  def send_email
    UserMailer.email_verification(
      user: user,
      raw_token: @raw_token,
      purpose: :email_change
    ).deliver_later
  end    

end
