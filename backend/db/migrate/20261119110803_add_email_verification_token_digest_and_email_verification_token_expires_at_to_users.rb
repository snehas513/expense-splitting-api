class AddEmailVerificationTokenDigestAndEmailVerificationTokenExpiresAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_verification_token_digest, :string, limit: 64
    add_column :users, :email_verification_token_expires_at, :datetime
  end
end
