module Api
  module V1
    class MembershipsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group
      before_action :authorize_group_membership, only: :index

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
    end
    
  end
end
