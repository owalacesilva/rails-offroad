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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_140010) do
  create_table "ad_images", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "ad_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "file_url", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["ad_id", "sort_order"], name: "index_ad_images_on_ad_id_and_sort_order"
    t.index ["ad_id"], name: "index_ad_images_on_ad_id"
  end

  create_table "admin_sessions", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "admin_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["admin_id"], name: "index_admin_sessions_on_admin_id"
  end

  create_table "admins", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_hash", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "ads", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "admin_id", limit: 36
    t.integer "badge"
    t.string "category_id", limit: 36, null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "price", precision: 12, scale: 2, null: false
    t.datetime "published_at"
    t.datetime "reviewed_at"
    t.string "state", limit: 2, null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36, null: false
    t.integer "year"
    t.index ["admin_id"], name: "index_ads_on_admin_id"
    t.index ["category_id"], name: "index_ads_on_category_id"
    t.index ["price"], name: "index_ads_on_price"
    t.index ["published_at"], name: "index_ads_on_published_at"
    t.index ["state", "city"], name: "index_ads_on_state_and_city"
    t.index ["status"], name: "index_ads_on_status"
    t.index ["user_id"], name: "index_ads_on_user_id"
    t.index ["year"], name: "index_ads_on_year"
    t.check_constraint "`price` > 0", name: "ads_price_positive"
    t.check_constraint "`status` in (_utf8mb4'draft',_utf8mb4'pending',_utf8mb4'approved',_utf8mb4'rejected')", name: "ads_status_valid"
  end

  create_table "attributes", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_type", default: "STRING", null: false
    t.boolean "is_required", default: false, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_attributes_on_name", unique: true
    t.index ["position"], name: "index_attributes_on_position"
    t.check_constraint "`data_type` in (_utf8mb4'STRING',_utf8mb4'INT',_utf8mb4'DECIMAL')", name: "attributes_data_type_valid"
  end

  create_table "categories", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "proposals", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "ad_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message"
    t.string "name", null: false
    t.decimal "offered_value", precision: 12, scale: 2, null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36
    t.index ["ad_id"], name: "index_proposals_on_ad_id"
    t.index ["created_at"], name: "index_proposals_on_created_at"
    t.index ["user_id"], name: "index_proposals_on_user_id"
    t.check_constraint "`offered_value` > 0", name: "proposals_offered_value_positive"
  end

  create_table "sessions", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "user_id", limit: 36, null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "technical_spec_values", primary_key: ["ad_id", "attribute_id"], charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "ad_id", limit: 36, null: false
    t.string "attribute_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["attribute_id"], name: "index_technical_spec_values_on_attribute_id"
  end

  create_table "users", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.date "member_since", null: false
    t.string "name", null: false
    t.string "password_hash", null: false
    t.string "phone", null: false
    t.string "state", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "`state` in (_utf8mb4'AC',_utf8mb4'AL',_utf8mb4'AP',_utf8mb4'AM',_utf8mb4'BA',_utf8mb4'CE',_utf8mb4'DF',_utf8mb4'ES',_utf8mb4'GO',_utf8mb4'MA',_utf8mb4'MT',_utf8mb4'MS',_utf8mb4'MG',_utf8mb4'PA',_utf8mb4'PB',_utf8mb4'PR',_utf8mb4'PE',_utf8mb4'PI',_utf8mb4'RJ',_utf8mb4'RN',_utf8mb4'RS',_utf8mb4'RO',_utf8mb4'RR',_utf8mb4'SC',_utf8mb4'SP',_utf8mb4'SE',_utf8mb4'TO')", name: "users_state_valid"
  end

  add_foreign_key "ad_images", "ads"
  add_foreign_key "admin_sessions", "admins"
  add_foreign_key "ads", "admins"
  add_foreign_key "ads", "categories"
  add_foreign_key "ads", "users"
  add_foreign_key "proposals", "ads"
  add_foreign_key "proposals", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "technical_spec_values", "ads"
  add_foreign_key "technical_spec_values", "attributes"
end
