class AddPendingInvitationConstraintToInvitations < ActiveRecord::Migration[8.1]
  def change
    execute <<~SQL
      ALTER TABLE invitations
      ADD COLUMN pending_invitation_key VARCHAR(100)
      GENERATED ALWAYS AS (
        CASE
          WHEN status = 'pending'
          THEN CONCAT(invited_user_id, ':', group_id)
          ELSE NULL
        END
      ) STORED
    SQL

    add_index :invitations, :pending_invitation_key, unique: true
  end
end
