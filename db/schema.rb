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

ActiveRecord::Schema[8.1].define(version: 2026_08_18_160001) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ad_images", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ad_id", null: false
    t.datetime "blocked_at"
    t.datetime "created_at", null: false
    t.string "file_url"
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["ad_id", "sort_order"], name: "index_ad_images_on_ad_id_and_sort_order"
    t.index ["ad_id"], name: "index_ad_images_on_ad_id"
    t.index ["blocked_at"], name: "index_ad_images_on_blocked_at"
  end

  create_table "admin_sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["admin_id"], name: "index_admin_sessions_on_admin_id"
  end

  create_table "admins", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_hash", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "ads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "admin_id"
    t.integer "badge"
    t.bigint "category_id", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "moderation_note"
    t.integer "price_cents", null: false
    t.datetime "published_at"
    t.datetime "reviewed_at"
    t.string "slug", null: false
    t.string "state", limit: 2, null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.integer "year"
    t.index ["admin_id"], name: "index_ads_on_admin_id"
    t.index ["category_id"], name: "index_ads_on_category_id"
    t.index ["price_cents"], name: "index_ads_on_price_cents"
    t.index ["published_at"], name: "index_ads_on_published_at"
    t.index ["slug"], name: "index_ads_on_slug", unique: true
    t.index ["state", "city"], name: "index_ads_on_state_and_city"
    t.index ["status"], name: "index_ads_on_status"
    t.index ["user_id"], name: "index_ads_on_user_id"
    t.index ["views_count"], name: "index_ads_on_views_count"
    t.index ["year"], name: "index_ads_on_year"
    t.check_constraint "`price_cents` > 0", name: "ads_price_positive"
    t.check_constraint "`status` in (_utf8mb4'draft',_utf8mb4'pending',_utf8mb4'approved',_utf8mb4'rejected')", name: "ads_status_valid"
    t.check_constraint "`views_count` >= 0", name: "ads_views_count_not_negative"
  end

  create_table "attribute_categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "attribute_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attribute_id"], name: "index_attribute_categories_on_attribute_id"
    t.index ["category_id", "attribute_id"], name: "index_attribute_categories_on_category_id_and_attribute_id", unique: true
    t.index ["category_id"], name: "index_attribute_categories_on_category_id"
  end

  create_table "attributes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_type", default: "STRING", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_attributes_on_name", unique: true
    t.index ["position"], name: "index_attributes_on_position"
    t.check_constraint "`data_type` in (_utf8mb4'STRING',_utf8mb4'INT',_utf8mb4'DECIMAL')", name: "attributes_data_type_valid"
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "cities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ibge_code", limit: 7, null: false
    t.string "name", null: false
    t.string "state", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["ibge_code"], name: "index_cities_on_ibge_code", unique: true
    t.index ["state", "name"], name: "index_cities_on_state_and_name", unique: true
    t.check_constraint "`state` in (_utf8mb4'AC',_utf8mb4'AL',_utf8mb4'AP',_utf8mb4'AM',_utf8mb4'BA',_utf8mb4'CE',_utf8mb4'DF',_utf8mb4'ES',_utf8mb4'GO',_utf8mb4'MA',_utf8mb4'MT',_utf8mb4'MS',_utf8mb4'MG',_utf8mb4'PA',_utf8mb4'PB',_utf8mb4'PR',_utf8mb4'PE',_utf8mb4'PI',_utf8mb4'RJ',_utf8mb4'RN',_utf8mb4'RS',_utf8mb4'RO',_utf8mb4'RR',_utf8mb4'SC',_utf8mb4'SP',_utf8mb4'SE',_utf8mb4'TO')", name: "cities_state_valid"
    t.check_constraint "regexp_like(`ibge_code`,_utf8mb4'^[1-9][0-9]{6}$')", name: "cities_ibge_code_valid"
  end

  create_table "events", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "ends_on"
    t.boolean "featured", default: false, null: false
    t.string "image_url"
    t.date "starts_on", null: false
    t.string "state", limit: 2, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "venue"
    t.index ["featured"], name: "index_events_on_featured"
    t.index ["starts_on"], name: "index_events_on_starts_on"
    t.index ["state", "city"], name: "index_events_on_state_and_city"
    t.check_constraint "(`ends_on` is null) or (`ends_on` >= `starts_on`)", name: "events_dates_ordered"
    t.check_constraint "`state` in (_utf8mb4'AC',_utf8mb4'AL',_utf8mb4'AP',_utf8mb4'AM',_utf8mb4'BA',_utf8mb4'CE',_utf8mb4'DF',_utf8mb4'ES',_utf8mb4'GO',_utf8mb4'MA',_utf8mb4'MT',_utf8mb4'MS',_utf8mb4'MG',_utf8mb4'PA',_utf8mb4'PB',_utf8mb4'PR',_utf8mb4'PE',_utf8mb4'PI',_utf8mb4'RJ',_utf8mb4'RN',_utf8mb4'RS',_utf8mb4'RO',_utf8mb4'RR',_utf8mb4'SC',_utf8mb4'SP',_utf8mb4'SE',_utf8mb4'TO')", name: "events_state_valid"
  end

  create_table "newsletter_subscriptions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscriptions_on_email", unique: true
  end

  create_table "posts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.text "body", null: false
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_posts_on_admin_id"
    t.index ["published_at"], name: "index_posts_on_published_at"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "proposals", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ad_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message"
    t.string "name", null: false
    t.integer "offered_value_cents", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["ad_id"], name: "index_proposals_on_ad_id"
    t.index ["created_at"], name: "index_proposals_on_created_at"
    t.index ["user_id"], name: "index_proposals_on_user_id"
    t.check_constraint "`offered_value_cents` > 0", name: "proposals_offered_value_positive"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "technical_spec_values", primary_key: ["ad_id", "attribute_id"], charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ad_id", null: false
    t.bigint "attribute_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["attribute_id"], name: "index_technical_spec_values_on_attribute_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "ads_count", default: 0, null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.date "member_since", null: false
    t.string "name", null: false
    t.string "password_hash", null: false
    t.string "phone", null: false
    t.string "state", limit: 2, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["ads_count"], name: "index_users_on_ads_count"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.check_constraint "`state` in (_utf8mb4'AC',_utf8mb4'AL',_utf8mb4'AP',_utf8mb4'AM',_utf8mb4'BA',_utf8mb4'CE',_utf8mb4'DF',_utf8mb4'ES',_utf8mb4'GO',_utf8mb4'MA',_utf8mb4'MT',_utf8mb4'MS',_utf8mb4'MG',_utf8mb4'PA',_utf8mb4'PB',_utf8mb4'PR',_utf8mb4'PE',_utf8mb4'PI',_utf8mb4'RJ',_utf8mb4'RN',_utf8mb4'RS',_utf8mb4'RO',_utf8mb4'RR',_utf8mb4'SC',_utf8mb4'SP',_utf8mb4'SE',_utf8mb4'TO')", name: "users_state_valid"
    t.check_constraint "`status` in (_utf8mb4'active',_utf8mb4'inactive',_utf8mb4'blocked')", name: "users_status_valid"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ad_images", "ads"
  add_foreign_key "admin_sessions", "admins"
  add_foreign_key "ads", "admins"
  add_foreign_key "ads", "categories"
  add_foreign_key "ads", "users"
  add_foreign_key "attribute_categories", "attributes"
  add_foreign_key "attribute_categories", "categories"
  add_foreign_key "posts", "admins"
  add_foreign_key "proposals", "ads"
  add_foreign_key "proposals", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "technical_spec_values", "ads"
  add_foreign_key "technical_spec_values", "attributes"
end
