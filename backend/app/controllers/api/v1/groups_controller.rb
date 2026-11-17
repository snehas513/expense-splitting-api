module Api
  module V1
    class GroupsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group, only: :show

      def create
        response = Groups::CreateService.new(**group_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :created
      end

      def index
        response = Groups::IndexService.new(user: current_user).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def show
        response = Groups::ShowService.new(**fetch_group_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def group_attributes
        params.permit(:name, :description).to_h.symbolize_keys.merge(
          creator: current_user
        )
      end

      def fetch_group_attributes
        {
          user: current_user,
          group: @group
        }
      end

    end
  end
end