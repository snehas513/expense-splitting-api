module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_notification, only: :mark_as_read

      def index
        notifications = current_user.notifications.unread.order(created_at: :desc)
        render json: { success: true, notifications: notifications }, status: :ok
      end

      def mark_as_read
        response = Notifications::MarkAsReadService.new(notification: @notification).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def set_notification
        @notification = current_user.notifications.find_by(id: params[:id])
      end

    end
  end
end