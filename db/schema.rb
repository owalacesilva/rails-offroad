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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_025211) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "advertisers", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.date "member_since", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.string "state", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_advertisers_on_email", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "advertiser_id", null: false
    t.integer "badge"
    t.bigint "category_id", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "price_cents", null: false
    t.datetime "published_at", null: false
    t.jsonb "specifications", default: {}, null: false
    t.string "state", limit: 2, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["advertiser_id"], name: "index_listings_on_advertiser_id"
    t.index ["category_id"], name: "index_listings_on_category_id"
    t.index ["price_cents"], name: "index_listings_on_price_cents"
    t.index ["published_at"], name: "index_listings_on_published_at"
    t.index ["state", "city"], name: "index_listings_on_state_and_city"
    t.index ["year"], name: "index_listings_on_year"
    t.check_constraint "price_cents > 0", name: "listings_price_cents_positive"
  end

  create_table "proposals", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "listing_id", null: false
    t.text "message"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_proposals_on_created_at"
    t.index ["listing_id"], name: "index_proposals_on_listing_id"
    t.check_constraint "amount_cents > 0", name: "proposals_amount_cents_positive"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "listings", "advertisers"
  add_foreign_key "listings", "categories"
  add_foreign_key "proposals", "listings"
end
