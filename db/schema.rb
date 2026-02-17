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

ActiveRecord::Schema[8.1].define(version: 2026_02_17_160751) do
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

  create_table "buy_list_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "plant_category_id"
    t.bigint "plant_id"
    t.bigint "plant_subcategory_id"
    t.datetime "purchased_at"
    t.bigint "seed_purchase_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["plant_category_id"], name: "index_buy_list_items_on_plant_category_id"
    t.index ["plant_id"], name: "index_buy_list_items_on_plant_id"
    t.index ["plant_subcategory_id"], name: "index_buy_list_items_on_plant_subcategory_id"
    t.index ["seed_purchase_id"], name: "index_buy_list_items_on_seed_purchase_id"
    t.check_constraint "plant_category_id IS NOT NULL AND plant_subcategory_id IS NULL AND plant_id IS NULL OR plant_category_id IS NULL AND plant_subcategory_id IS NOT NULL AND plant_id IS NULL OR plant_category_id IS NULL AND plant_subcategory_id IS NULL AND plant_id IS NOT NULL", name: "chk_buy_list_item_exactly_one_target"
  end

  create_table "growing_guides", force: :cascade do |t|
    t.boolean "ai_generated", default: false, null: false
    t.datetime "ai_generated_at"
    t.datetime "created_at", null: false
    t.integer "germination_days_max"
    t.integer "germination_days_min"
    t.integer "germination_temp_max_f"
    t.integer "germination_temp_min_f"
    t.text "growing_tips"
    t.text "harvest_notes"
    t.text "overview"
    t.bigint "plant_category_id"
    t.bigint "plant_subcategory_id"
    t.decimal "planting_depth_inches"
    t.integer "row_spacing_inches"
    t.text "seed_saving_notes"
    t.text "soil_requirements"
    t.integer "spacing_inches"
    t.integer "sun_exposure"
    t.datetime "updated_at", null: false
    t.integer "water_needs"
    t.index ["plant_category_id"], name: "index_growing_guides_on_plant_category_id"
    t.index ["plant_category_id"], name: "index_growing_guides_on_plant_category_id_unique", unique: true, where: "(plant_category_id IS NOT NULL)"
    t.index ["plant_subcategory_id"], name: "index_growing_guides_on_plant_subcategory_id"
    t.index ["plant_subcategory_id"], name: "index_growing_guides_on_plant_subcategory_id_unique", unique: true, where: "(plant_subcategory_id IS NOT NULL)"
    t.check_constraint "plant_category_id IS NOT NULL AND plant_subcategory_id IS NULL OR plant_category_id IS NULL AND plant_subcategory_id IS NOT NULL", name: "chk_growing_guide_belongs_to_one"
  end

  create_table "plant_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "expected_viability_years"
    t.boolean "expected_viability_years_ai_populated", default: false, null: false
    t.string "latin_genus"
    t.boolean "latin_genus_ai_populated", default: false, null: false
    t.string "latin_species"
    t.boolean "latin_species_ai_populated", default: false, null: false
    t.string "name", null: false
    t.bigint "plant_type_id", null: false
    t.integer "position"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_type_id", "name"], name: "index_plant_categories_on_plant_type_id_and_name", unique: true
    t.index ["plant_type_id", "slug"], name: "index_plant_categories_on_plant_type_id_and_slug", unique: true
    t.index ["plant_type_id"], name: "index_plant_categories_on_plant_type_id"
  end

  create_table "plant_subcategories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "plant_category_id", null: false
    t.integer "position"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_category_id", "name"], name: "index_plant_subcategories_on_plant_category_id_and_name", unique: true
    t.index ["plant_category_id", "slug"], name: "index_plant_subcategories_on_plant_category_id_and_slug", unique: true
    t.index ["plant_category_id"], name: "index_plant_subcategories_on_plant_category_id"
  end

  create_table "plant_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_plant_types_on_name", unique: true
    t.index ["slug"], name: "index_plant_types_on_slug", unique: true
  end

  create_table "plants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "days_to_harvest_max"
    t.integer "days_to_harvest_min"
    t.integer "expected_viability_years"
    t.boolean "heirloom", default: false, null: false
    t.string "latin_name"
    t.boolean "latin_name_ai_populated", default: false, null: false
    t.integer "life_cycle", null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "plant_category_id", null: false
    t.bigint "plant_subcategory_id"
    t.string "planting_seasons", default: [], array: true
    t.text "references_urls", default: [], array: true
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.text "variety_description"
    t.boolean "variety_description_ai_populated", default: false, null: false
    t.integer "winter_hardy"
    t.index ["plant_category_id", "plant_subcategory_id", "slug"], name: "index_plants_on_category_subcategory_slug", unique: true
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

  create_table "spreadsheet_import_rows", force: :cascade do |t|
    t.jsonb "ai_mapping_data", default: {}
    t.datetime "created_at", null: false
    t.boolean "detected_used_up", default: false, null: false
    t.bigint "duplicate_of_row_id"
    t.decimal "germination_rate", precision: 5, scale: 4
    t.boolean "has_gray_text", default: false, null: false
    t.string "mapped_category_name"
    t.string "mapped_plant_type_name"
    t.string "mapped_source_name"
    t.string "mapped_subcategory_name"
    t.decimal "mapping_confidence", precision: 3, scale: 2
    t.text "mapping_notes"
    t.integer "mapping_status", default: 0, null: false
    t.text "notes"
    t.jsonb "parse_warnings", default: []
    t.integer "quantity", default: 1
    t.jsonb "raw_data", default: {}
    t.string "raw_date_value"
    t.string "raw_germination_value"
    t.integer "row_number", null: false
    t.string "seed_source_name"
    t.string "sheet_name", null: false
    t.bigint "spreadsheet_import_id", null: false
    t.datetime "updated_at", null: false
    t.string "variety_name"
    t.integer "year_purchased"
    t.index ["duplicate_of_row_id"], name: "index_spreadsheet_import_rows_on_duplicate_of_row_id"
    t.index ["spreadsheet_import_id", "sheet_name", "row_number"], name: "idx_import_rows_on_import_sheet_row", unique: true
    t.index ["spreadsheet_import_id"], name: "index_spreadsheet_import_rows_on_spreadsheet_import_id"
  end

  create_table "spreadsheet_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "executed_rows", default: 0
    t.jsonb "import_report", default: {}
    t.integer "mapped_rows", default: 0
    t.string "original_filename", null: false
    t.integer "parsed_rows", default: 0
    t.jsonb "sheet_names", default: []
    t.integer "status", default: 0, null: false
    t.integer "total_rows", default: 0
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "buy_list_items", "plant_categories"
  add_foreign_key "buy_list_items", "plant_subcategories"
  add_foreign_key "buy_list_items", "plants"
  add_foreign_key "buy_list_items", "seed_purchases"
  add_foreign_key "growing_guides", "plant_categories"
  add_foreign_key "growing_guides", "plant_subcategories"
  add_foreign_key "plant_categories", "plant_types"
  add_foreign_key "plant_subcategories", "plant_categories"
  add_foreign_key "plants", "plant_categories"
  add_foreign_key "plants", "plant_subcategories"
  add_foreign_key "seed_purchases", "plants"
  add_foreign_key "seed_purchases", "seed_sources"
  add_foreign_key "spreadsheet_import_rows", "spreadsheet_imports"
end
