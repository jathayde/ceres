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

ActiveRecord::Schema[8.1].define(version: 2026_02_16_234254) do
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

  add_foreign_key "plant_categories", "plant_types"
  add_foreign_key "plant_subcategories", "plant_categories"
  add_foreign_key "plants", "plant_categories"
  add_foreign_key "plants", "plant_subcategories"
end
