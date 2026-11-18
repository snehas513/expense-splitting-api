module Api
  module V1
    class InvitationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group, except: :user_index
      before_action :set_invited_user, only: :create
      before_action :set_invitation, only: [:accept, :reject]
      before_action :authorize_group_membership, only: :index

      def create
        response = Invitations::CreateService.new(**invitation_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :created
      end

      def accept
        response = Invitations::AcceptService.new(**update_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def reject
        response = Invitations::RejectService.new(**update_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def index
        response = Invitations::IndexService.new(**fetch_invitations_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def user_index
        response = Invitations::UserIndexService.new(user: current_user).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def invitation_attributes
        {
          group: @group,
          invited_by: current_user,
          invited_user: @invited_user
        }
      end

      def set_invited_user
        @invited_user = User.find_by(id: params[:invited_user_id])
      end

      def update_attributes
        {
          invitation: @invitation,
          user: current_user
        }
      end

      def set_invitation
        @invitation = @group.invitations.find_by(id: params[:id])
      end

      def fetch_invitations_attributes
        {
          group: @group,
          user: current_user
        }
      end

    end
  end
end