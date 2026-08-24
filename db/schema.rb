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

ActiveRecord::Schema[8.1].define(version: 2026_08_24_164642) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "asset_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_asset_categories_on_name", unique: true
    t.index ["slug"], name: "index_asset_categories_on_slug", unique: true
  end

  create_table "asset_units", force: :cascade do |t|
    t.integer "asset_id", null: false
    t.string "asset_tag", null: false
    t.string "condition", default: "good", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "serial_number", null: false
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_asset_units_on_asset_id"
    t.index ["asset_tag"], name: "index_asset_units_on_asset_tag", unique: true
    t.index ["serial_number"], name: "index_asset_units_on_serial_number", unique: true
    t.index ["status"], name: "index_asset_units_on_status"
  end

  create_table "assets", force: :cascade do |t|
    t.integer "asset_category_id", null: false
    t.string "brand", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "model", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_category_id"], name: "index_assets_on_asset_category_id"
    t.index ["brand", "model"], name: "index_assets_on_brand_and_model", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "department"
    t.string "email_address", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", null: false
    t.string "role", default: "employee", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "asset_units", "assets"
  add_foreign_key "assets", "asset_categories"
  add_foreign_key "sessions", "users"
end
