class AddActiveMembershipConstraintToMemberships < ActiveRecord::Migration[8.1]
  def change
    execute <<~SQL
      ALTER TABLE memberships
      ADD COLUMN active_membership_key VARCHAR(100)
      GENERATED ALWAYS AS (
        CASE
          WHEN status = 'active'
          THEN CONCAT(user_id, ':', group_id)
          ELSE NULL
        END
      ) STORED
    SQL

    add_index :memberships, :active_membership_key, unique: true
  end
end
