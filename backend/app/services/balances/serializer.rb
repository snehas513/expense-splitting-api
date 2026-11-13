module Balances
  class Serializer

    attr_reader :balances_hash

    def initialize(balances_hash:)
      @balances_hash = balances_hash
    end

    def call
      serialize_response
    end

    private

    def serialize_response
        users = User.where(id: balances_hash.keys).index_by(&:id)
        balances_array = balances_hash.map do |user_id, balance|
                          {
                            "user_id": user_id,
                            "name": users[user_id].name,
                            "balance": format("%.2f", balance)
                          }
                        end
        { success: true, balances: balances_array }
      end
  end
end