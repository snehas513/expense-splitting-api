module Api
  module V1
    class SettlementsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group
      before_action :set_sender, only: :create
      before_action :set_receiver, only: :create
      before_action :set_settlement, only: [:confirm, :reject, :cancel]
      before_action :authorize_group_membership, only: :index

      def create
        response = Settlements::CreateService.new(**settlement_attributes).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :created
      end

      def confirm
        response = Settlements::ConfirmService.new(**update_settlement_attributes).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def reject
        response = Settlements::RejectService.new(**update_settlement_attributes).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def cancel
        response = Settlements::CancelService.new(**update_settlement_attributes).call
        
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      def index
        response = Settlements::IndexService.new(**fetch_settlement_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :ok
      end

      private

      def set_sender
        @sender = User.find_by(id: params[:sender_id])
        unless @sender
          return render json: { error: "Sender not found" }, status: :not_found
        end
      end

      def set_receiver
        @receiver = User.find_by(id: params[:receiver_id])
        unless @receiver
          return render json: { error: "Receiver not found" }, status: :not_found
        end
      end

      def settlement_attributes
        attributes = settlement_params

        {
          group: @group,
          sender: @sender,
          receiver: @receiver,
          creator: current_user,
          settlement_amount: attributes["settlement_amount"],
          settlement_date: attributes["settlement_date"],
          allocations: (attributes["allocations"] || []).map do |allocation|
            allocation.deep_symbolize_keys
          end,
          note: attributes["note"]
        }
      end

      def set_settlement
        @settlement = @group.settlements.find_by(id: params[:id])
        unless @settlement
          return render json: { error: "Settlement not found" }, status: :not_found
        end
      end

      def update_settlement_attributes
        {
          group: @group,
          settlement: @settlement,
          acted_by: current_user
        }
      end

      def fetch_settlement_attributes
        {
          group_id: @group.id,
          status: params[:status],
          limit: params[:limit],
          cursor: params[:cursor]
        }
      end

      def settlement_params
        params.permit(
          :sender_id,
          :receiver_id,
          :settlement_amount,
          :settlement_date,
          :note,
          allocations: [:expense_id, :allocation_amount]
        ).to_h
      end
    end
  end
end