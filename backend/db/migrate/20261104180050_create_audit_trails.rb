class CreateAuditTrails < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_trails do |t|
      t.references :user, null: true, foreign_key: true
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.string :action, null: false
      t.json :changes
    
      t.timestamps null: false
    end
    add_index :audit_trails, [:auditable_type, :auditable_id],
          name: "index_audit_trails_on_auditable"
  end
end
