class RenameChangesToChangeDetailsInAuditTrails < ActiveRecord::Migration[8.1]
  def change
    rename_column :audit_trails, :changes, :change_details
  end
end