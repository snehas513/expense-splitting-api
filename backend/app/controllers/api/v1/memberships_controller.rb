module Api
  module V1
    class MembershipsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group
      before_action :authorize_group_membership, only: :index
      before_action :set_target_user, only: [:remove, :update_role]

      def index
        response = Memberships::IndexService.new(group: @group).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def leave
        response = Memberships::LeaveService.new(group: @group, user: current_user).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def remove
        response = Memberships::RemoveService.new(**remove_membership_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def update_role
        response = Memberships::UpdateService.new(**update_role_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def remove_membership_attributes
        {
          group: @group, 
          admin: current_user,
          user: @target_user
        }
      end

      def set_target_user
        @target_user = User.find_by(id: params[:target_user_id])
      end

      def update_role_attributes
        {
          group: @group, 
          admin: current_user,
          user: @target_user,
          role: params[:role]
        }
      end
    end

  end
end
