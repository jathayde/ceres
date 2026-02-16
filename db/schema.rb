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

ActiveRecord::Schema[8.1].define(version: 2026_02_16_234745) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "plant_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "expected_viability_years"
    t.string "latin_genus"
    t.string "latin_species"
    t.string "name", null: false
    t.bigint "plant_type_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["plant_type_id", "name"], name: "index_plant_categories_on_plant_type_id_and_name", unique: true
    t.index ["plant_type_id"], name: "index_plant_categories_on_plant_type_id"
  end

  create_table "plant_subcategories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "plant_category_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["plant_category_id", "name"], name: "index_plant_subcategories_on_plant_category_id_and_name", unique: true
    t.index ["plant_category_id"], name: "index_plant_subcategories_on_plant_category_id"
  end

  create_table "plant_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_plant_types_on_name", unique: true
  end

  create_table "plants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "days_to_harvest_max"
    t.integer "days_to_harvest_min"
    t.integer "expected_viability_years"
    t.boolean "heirloom", default: false, null: false
    t.string "latin_name"
    t.integer "life_cycle", null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "plant_category_id", null: false
    t.bigint "plant_subcategory_id"
    t.string "planting_seasons", default: [], array: true
    t.text "references_urls", default: [], array: true
    t.datetime "updated_at", null: false
    t.integer "winter_hardy"
    t.index ["plant_category_id"], name: "index_plants_on_plant_category_id"
    t.index ["plant_subcategory_id"], name: "index_plants_on_plant_subcategory_id"
  end

  create_table "seed_purchases", force: :cascade do |t|
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.decimal "germination_rate", precision: 5, scale: 4
    t.string "lot_number"
    t.text "notes"
    t.integer "packet_count", default: 1
    t.bigint "plant_id", null: false
    t.string "reorder_url"
    t.integer "seed_count"
    t.bigint "seed_source_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "used_up", default: false, null: false
    t.date "used_up_at"
    t.decimal "weight_oz"
    t.integer "year_purchased", null: false
    t.index ["plant_id"], name: "index_seed_purchases_on_plant_id"
    t.index ["seed_source_id"], name: "index_seed_purchases_on_seed_source_id"
  end

  create_table "seed_sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["name"], name: "index_seed_sources_on_name", unique: true
  end

  add_foreign_key "plant_categories", "plant_types"
  add_foreign_key "plant_subcategories", "plant_categories"
  add_foreign_key "plants", "plant_categories"
  add_foreign_key "plants", "plant_subcategories"
  add_foreign_key "seed_purchases", "plants"
  add_foreign_key "seed_purchases", "seed_sources"
end
