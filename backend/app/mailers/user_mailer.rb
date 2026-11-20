class UserMailer < ApplicationMailer
  def email_verification(user:, raw_token:, purpose:)
    @user = user
    @raw_token = raw_token
    @purpose = purpose

    recipient = nil
    subject = nil

    if @purpose == :registration
      recipient = user.email
      subject = "Verify your registration"
    elsif @purpose == :email_change
      recipient = user.pending_email
      subject = "Verify your new email address"
    end

    frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:8501")
    @verification_url = "#{frontend_url}/verify-email?token=#{ERB::Util.url_encode(@raw_token)}"

    mail(
      to: recipient,
      subject: subject
    )
  end

  def email_change_confirmation(user:, purpose:)
    @user = user
    @purpose = purpose

    recipient = nil
    subject = nil

    if @purpose == :email_change
      recipient = user.email
      subject = "Your email address has been updated"
    end

    mail(
      to: recipient,
      subject: subject
    )
  end
end