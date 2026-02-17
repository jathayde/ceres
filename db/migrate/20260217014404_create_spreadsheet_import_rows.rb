class CreateSpreadsheetImportRows < ActiveRecord::Migration[8.1]
  def change
    create_table :spreadsheet_import_rows do |t|
      t.references :spreadsheet_import, null: false, foreign_key: true
      t.string :sheet_name, null: false
      t.integer :row_number, null: false
      t.string :variety_name
      t.string :seed_source_name
      t.integer :year_purchased
      t.string :raw_date_value
      t.decimal :germination_rate, precision: 5, scale: 4
      t.string :raw_germination_value
      t.text :notes
      t.boolean :detected_used_up, default: false, null: false
      t.boolean :has_gray_text, default: false, null: false
      t.jsonb :raw_data, default: {}
      t.jsonb :parse_warnings, default: []
      t.timestamps
    end

    add_index :spreadsheet_import_rows, [ :spreadsheet_import_id, :sheet_name, :row_number ],
              name: "idx_import_rows_on_import_sheet_row", unique: true
  end
end
