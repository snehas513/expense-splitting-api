class UserMailer < ApplicationMailer
  def email_verification(user:, raw_token:)
    @user = user
    @raw_token = raw_token

    frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:8501")
    @verification_url = "#{frontend_url}/verify-email?token=#{ERB::Util.url_encode(@raw_token)}"

    mail(
      to: @user.pending_email,
      subject: "Verify your new email address"
    )
  end

  def email_change_confirmation(user:)
    @user = user

    mail(
      to: @user.email,
      subject: "Your email address has been updated"
    )
  end
end