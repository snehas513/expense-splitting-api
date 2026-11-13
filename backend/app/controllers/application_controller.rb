class ApplicationController < ActionController::API
  include Authenticatable

  def set_group
    @group = Group.find_by(id: params[:group_id])

    unless @group
      render json: { error: "Group not found" }, status: :not_found
    end
  end

  def authorize_group_membership
    membership = Membership.find_by(
      user_id: current_user.id,
      group_id: @group.id,
      status: "active"
    )

    unless membership
      render json: {
        error: "Authenticated user, but no active membership"
      }, status: :forbidden
    end
  end
end