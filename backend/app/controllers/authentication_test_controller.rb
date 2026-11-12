class AuthenticationTestController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: { success: true }, status: :ok
  end
end