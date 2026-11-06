class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :group, null: false, foreign_key: true
      t.references :invited_user,
                   null: false,
                   foreign_key: { to_table: :users }
      t.references :invited_by,
                   null: false,
                   foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.datetime :sent_at, null: false
      t.datetime :responded_at
      t.datetime :revoked_at

      t.timestamps null: false
    end
  end
end
