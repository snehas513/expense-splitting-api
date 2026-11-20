module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!
      
      def index
        notifications = current_user.notifications.unread.order(created_at: :desc)
        render json: { success: true, notifications: notifications }, status: :ok
      end

    end
  end
end