class AddMappingFieldsToSpreadsheetImportRows < ActiveRecord::Migration[8.1]
  def change
    add_column :spreadsheet_import_rows, :mapped_plant_type_name, :string
    add_column :spreadsheet_import_rows, :mapped_category_name, :string
    add_column :spreadsheet_import_rows, :mapped_subcategory_name, :string
    add_column :spreadsheet_import_rows, :mapped_source_name, :string
    add_column :spreadsheet_import_rows, :mapping_status, :integer, default: 0, null: false
    add_column :spreadsheet_import_rows, :mapping_confidence, :decimal, precision: 3, scale: 2
    add_column :spreadsheet_import_rows, :ai_mapping_data, :jsonb, default: {}
    add_column :spreadsheet_import_rows, :duplicate_of_row_id, :bigint
    add_column :spreadsheet_import_rows, :mapping_notes, :text

    add_index :spreadsheet_import_rows, :duplicate_of_row_id
  end
end
