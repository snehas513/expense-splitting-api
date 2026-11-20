class Notifications::CreateService
  attr_reader :user, :notification_type, :message

  def initialize(user:, notification_type:, message:)
    @user = user
    @notification_type = notification_type
    @message = message
    @errors = []
  end
  
  def call
    validate
    return { success: false, errors: @errors } unless @errors.empty?
    
    create_notification
    { success: true, notification: @notification }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def validate
    validate_user
    validate_notification_type
    validate_message
  end

  def validate_user
    if user.blank?
      @errors << "User is required"
    elsif !user.active?
      @errors << "User must have an active account"
    end
  end

  def validate_notification_type
    @errors << "Notification type must be one of: #{Notification::NOTIFICATION_TYPES.join(', ')}" unless Notification::NOTIFICATION_TYPES.include?(notification_type)
  end

  def validate_message
    @errors << "Message is required" if message.blank?
  end

  def create_notification
    @notification = user.notifications.create!(
        notification_type: notification_type,
        message: message,
        read: false
      )
  end
end
