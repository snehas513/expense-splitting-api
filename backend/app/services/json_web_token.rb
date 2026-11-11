class JsonWebToken
  ALGORITHM = "HS256"

  def self.encode(payload, exp = 24.hours.from_now)
    raise "Payload is empty" unless payload.present?
    
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, self.secret_key, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, self.secret_key, true, { algorithm: ALGORITHM })
    decoded[0]
  rescue JWT::DecodeError
    nil
  end

  def self.secret_key
    Rails.application.credentials.jwt_secret ||
    raise("JWT secret is missing from Rails credentials")
  end
end