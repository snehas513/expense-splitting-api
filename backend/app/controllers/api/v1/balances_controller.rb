module Api
  module V1
    class BalancesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group
      before_action :authorize_group_membership, only: [:index, :show]
      before_action :set_member, only: :show

      def index
        response = Balances::IndexService.new(group: @group).call

        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: Balances::Serializer.new(balances_hash: response[:balances]).call, status: :ok
      end

      def show
        response = Balances::MemberBreakdownService.new(**show_attributes).call

        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def show_attributes
        {
          group: @group,
          user: current_user,
          member: @member
        }
      end

      def set_member
        @member = User.find_by(id: params[:member_id])
      end

    end
  end
end