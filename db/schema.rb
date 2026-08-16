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
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "ad_images", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ad_id", null: false
    t.datetime "created_at", null: false
    t.string "file_url", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["ad_id", "sort_order"], name: "index_ad_images_on_ad_id_and_sort_order"
    t.index ["ad_id"], name: "index_ad_images_on_ad_id"
  end

  create_table "admin_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["admin_id"], name: "index_admin_sessions_on_admin_id"
  end

  create_table "admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_hash", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "ads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_id"
    t.integer "badge"
    t.uuid "category_id", null: false
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
    t.uuid "user_id", null: false
    t.integer "year"
    t.index ["admin_id"], name: "index_ads_on_admin_id"
    t.index ["category_id"], name: "index_ads_on_category_id"
    t.index ["price"], name: "index_ads_on_price"
    t.index ["published_at"], name: "index_ads_on_published_at"
    t.index ["state", "city"], name: "index_ads_on_state_and_city"
    t.index ["status"], name: "index_ads_on_status"
    t.index ["user_id"], name: "index_ads_on_user_id"
    t.index ["year"], name: "index_ads_on_year"
    t.check_constraint "price > 0::numeric", name: "ads_price_positive"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'pending'::character varying, 'approved'::character varying, 'rejected'::character varying]::text[])", name: "ads_status_valid"
  end

  create_table "attributes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_type", default: "STRING", null: false
    t.boolean "is_required", default: false, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_attributes_on_name", unique: true
    t.index ["position"], name: "index_attributes_on_position"
    t.check_constraint "data_type::text = ANY (ARRAY['STRING'::character varying, 'INT'::character varying, 'DECIMAL'::character varying]::text[])", name: "attributes_data_type_valid"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "proposals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ad_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message"
    t.string "name", null: false
    t.decimal "offered_value", precision: 12, scale: 2, null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["ad_id"], name: "index_proposals_on_ad_id"
    t.index ["created_at"], name: "index_proposals_on_created_at"
    t.index ["user_id"], name: "index_proposals_on_user_id"
    t.check_constraint "offered_value > 0::numeric", name: "proposals_offered_value_positive"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "technical_spec_values", primary_key: ["ad_id", "attribute_id"], force: :cascade do |t|
    t.uuid "ad_id", null: false
    t.uuid "attribute_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["attribute_id"], name: "index_technical_spec_values_on_attribute_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.check_constraint "state::text = ANY (ARRAY['AC'::character varying, 'AL'::character varying, 'AP'::character varying, 'AM'::character varying, 'BA'::character varying, 'CE'::character varying, 'DF'::character varying, 'ES'::character varying, 'GO'::character varying, 'MA'::character varying, 'MT'::character varying, 'MS'::character varying, 'MG'::character varying, 'PA'::character varying, 'PB'::character varying, 'PR'::character varying, 'PE'::character varying, 'PI'::character varying, 'RJ'::character varying, 'RN'::character varying, 'RS'::character varying, 'RO'::character varying, 'RR'::character varying, 'SC'::character varying, 'SP'::character varying, 'SE'::character varying, 'TO'::character varying]::text[])", name: "users_state_valid"
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
