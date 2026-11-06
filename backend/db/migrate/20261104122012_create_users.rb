class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :pending_email
      t.datetime :email_verified_at
      t.string :password_digest, null: false
      t.string :status, null: false, default: "active"

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :pending_email, unique: true
  end
end