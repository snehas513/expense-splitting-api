class Notifications::MarkAsReadService
  attr_reader :notification

  def initialize(notification:)
    @notification = notification
  end
  
  def call
    return { success: false, errors: ["Notification is required"] } if notification.blank?
    
    update_notification
    { success: true, notification: notification }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end

  private

  def update_notification
    return if notification.read

    notification.update!(read: true)
  end
end