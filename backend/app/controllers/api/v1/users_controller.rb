module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!
      
      def profile
        render json: { success: true, user: current_user.profile_json }, status: :ok
      end

      def update_profile
        current_user.update!(name: user_attributes[:name])

        render json: { success: true, user: current_user.profile_json }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json:  { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def email_change
        response = Users::RequestEmailChangeService.new(**email_change_attributes).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def email_verification
        response = Users::VerifyEmailService.new(**email_verification_attributes).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def user_attributes
        params.permit(:name)
      end

      def email_change_attributes
        {
          user: current_user, 
          new_email: params[:new_email]
        }
      end

      def email_verification_attributes
        {
          user: current_user, 
          raw_token: params[:raw_token]
        }
      end

    end
  end
end