module Api
  module V1
    class GroupsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group, only: [:show, :update, :archive]

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

      def update
        response = Groups::UpdateService.new(**update_group_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def archive
        response = Groups::ArchiveService.new(**fetch_group_attributes).call
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

      def update_group_attributes
        attributes = params.permit(:name, :description).to_h.symbolize_keys
        {
          user: current_user,
          group: @group,
          attributes: attributes
        }
      end
    end
  end
end