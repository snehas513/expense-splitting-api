module Api
  module V1
    class BalancesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group
      before_action :authorize_group_membership, only: :index

      def index
        response = Balances::IndexService.new(group: @group).call

        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: Balances::Serializer.new(balances_hash: response[:balances]).call, status: :ok
      end

    end
  end
end