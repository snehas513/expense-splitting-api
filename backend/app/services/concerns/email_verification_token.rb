module EmailVerificationToken
  attr_reader :raw_token
  
  def generate_verification_token
    @raw_token = SecureRandom.urlsafe_base64(32)
  end

  def token_digest
    Digest::SHA256.hexdigest(raw_token)
  end

  def token_expires_at
    30.minutes.from_now
  end

  def valid_verification_token?(stored_digest)
    return false if raw_token.blank? || stored_digest.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      token_digest,
      stored_digest
    )
  end
end