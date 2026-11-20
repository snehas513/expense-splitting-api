module Api
  module V1
    class AuthController < ApplicationController

      def register
        response = Users::RegisterService.new(**user_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end

        verification_response = Users::RequestRegistrationVerificationService.new(user: response[:user]).call
        unless verification_response[:success]
          render json: verification_response, status: :unprocessable_entity
          return
        end

        render json: {
                  success: true,
                  message: "Registration successful. Please verify your email.",
                  user: response[:user].as_json
                }, status: :created
      end

      def verify_email
        user = set_user

        unless user
          render json: { success: false, errors: ["Invalid or expired verification token"] },
                status: :unprocessable_entity
          return
        end
        
        response = Users::VerifyRegistrationEmailService.new(
          user: user,
          raw_token: params[:raw_token]
        ).call

        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end

        render json: {
          success: true,
          message: "Email verification successful. You can login.",
          user: response[:user].as_json
        }, status: :ok
      end

      def login
        response = Users::LoginService.new(
          email: params[:email],
          password: params[:password]
        ).call

        unless response[:success]
          render json: response, status: :unauthorized
          return
        end

        render json: response, status: :ok
      end

      private

      def user_attributes
        params.permit(:name, :email, :password, :password_confirmation).to_h.symbolize_keys
      end

      def set_user
        digest = Digest::SHA256.hexdigest(params[:raw_token].to_s)
        User.find_by(email_verification_token_digest: digest)
      end

    end
  end
end