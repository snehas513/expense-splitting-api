# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_04_180050) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_trails", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.string "action", null: false
    t.json "changes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_trails_on_auditable"
    t.index ["user_id"], name: "index_audit_trails_on_user_id"
  end

  create_table "expense_participants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.bigint "user_id", null: false
    t.decimal "share_amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id", "user_id"], name: "index_expense_participants_on_expense_and_user", unique: true
    t.index ["expense_id"], name: "index_expense_participants_on_expense_id"
    t.index ["user_id"], name: "index_expense_participants_on_user_id"
    t.check_constraint "`share_amount` > 0", name: "expense_participants_share_positive"
  end

  create_table "expenses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "paid_by_id", null: false
    t.bigint "created_by_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.text "description", null: false
    t.text "note"
    t.string "status", default: "active", null: false
    t.date "expense_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_expenses_on_created_by_id"
    t.index ["group_id"], name: "index_expenses_on_group_id"
    t.index ["paid_by_id"], name: "index_expenses_on_paid_by_id"
    t.check_constraint "`amount` > 0", name: "expenses_amount_positive"
  end

  create_table "groups", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "invited_user_id", null: false
    t.bigint "invited_by_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "sent_at", null: false
    t.datetime "responded_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "pending_invitation_key", type: :string, limit: 100, as: "(case when (`status` = _utf8mb4'pending') then concat(`invited_user_id`,_utf8mb4':',`group_id`) else NULL end)", stored: true
    t.index ["group_id"], name: "index_invitations_on_group_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["invited_user_id"], name: "index_invitations_on_invited_user_id"
    t.index ["pending_invitation_key"], name: "index_invitations_on_pending_invitation_key", unique: true
  end

  create_table "memberships", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "member", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "active_membership_key", type: :string, limit: 100, as: "(case when (`status` = _utf8mb4'active') then concat(`user_id`,_utf8mb4':',`group_id`) else NULL end)", stored: true
    t.index ["active_membership_key"], name: "index_memberships_on_active_membership_key", unique: true
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notification_type", null: false
    t.text "message", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "settlements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "sender_id", null: false
    t.bigint "receiver_id", null: false
    t.decimal "settlement_amount", precision: 12, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.date "settlement_date", null: false
    t.text "note"
    t.bigint "acted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acted_by_id"], name: "index_settlements_on_acted_by_id"
    t.index ["group_id"], name: "index_settlements_on_group_id"
    t.index ["receiver_id"], name: "index_settlements_on_receiver_id"
    t.index ["sender_id"], name: "index_settlements_on_sender_id"
    t.check_constraint "`sender_id` <> `receiver_id`", name: "settlements_sender_receiver_different"
    t.check_constraint "`settlement_amount` > 0", name: "settlements_amount_positive"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "pending_email"
    t.datetime "email_verified_at"
    t.string "password_digest", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["pending_email"], name: "index_users_on_pending_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_trails", "users"
  add_foreign_key "expense_participants", "expenses"
  add_foreign_key "expense_participants", "users"
  add_foreign_key "expenses", "groups"
  add_foreign_key "expenses", "users", column: "created_by_id"
  add_foreign_key "expenses", "users", column: "paid_by_id"
  add_foreign_key "invitations", "groups"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "invitations", "users", column: "invited_user_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "settlements", "groups"
  add_foreign_key "settlements", "users", column: "acted_by_id"
  add_foreign_key "settlements", "users", column: "receiver_id"
  add_foreign_key "settlements", "users", column: "sender_id"
end
