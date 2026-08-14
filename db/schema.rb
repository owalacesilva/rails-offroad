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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_015954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "listings", force: :cascade do |t|
    t.integer "badge"
    t.bigint "category_id", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.integer "price_cents", null: false
    t.datetime "published_at", null: false
    t.string "state", limit: 2, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["category_id"], name: "index_listings_on_category_id"
    t.index ["price_cents"], name: "index_listings_on_price_cents"
    t.index ["published_at"], name: "index_listings_on_published_at"
    t.index ["state", "city"], name: "index_listings_on_state_and_city"
    t.index ["year"], name: "index_listings_on_year"
    t.check_constraint "price_cents > 0", name: "listings_price_cents_positive"
  end

  add_foreign_key "listings", "categories"
end
