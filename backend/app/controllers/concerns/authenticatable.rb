module Authenticatable

  def authenticate_user!
    token = fetch_token
    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload["user_id"]) if payload.present?
    unless @current_user&.active?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
  end

  def fetch_token
    authorization_header = request.headers["Authorization"]
    scheme, token = authorization_header&.split(" ", 2)
    return nil unless scheme == "Bearer"
    token
  end

  def current_user
    @current_user
  end

end
