module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group
      before_action :set_payer
      before_action :set_participants

      def create
        response = Expenses::CreateService.new(**expense_attributes).call
        unless response[:success]
          render json: response, status: :unprocessable_entity
          return
        end
        render json: response, status: :created
      end

      private

      def set_group
        @group = Group.find_by(id: params[:group_id])
        unless @group
          return render json: { error: "Group not found" }, status: :not_found
        end
      end

      def set_payer
        @payer = User.find_by(id: params[:payer_id])
        unless @payer
          return render json: { error: "Payer not found" }, status: :not_found
        end
      end

      def set_participants
        participant_ids = params[:participant_ids]
        unless participant_ids.is_a?(Array)
          return render json: { error: "participant_ids must be an array" }, status: :bad_request
        end

        users_by_id = User.where(id: participant_ids).index_by(&:id)
        @participants = participant_ids.filter_map { |id| users_by_id[id.to_i] }
        
        unless @participants.count == participant_ids.count
          return render json: { error: "All participants should exist" }, status: :not_found
        end
      end

      def expense_attributes
        {
          group: @group,
          creator: current_user,
          payer: @payer,
          participants: @participants,
          amount: params[:amount],
          description: params[:description],
          expense_date: params[:expense_date],
          note: params[:note]
        }
      end
    end
  end
end