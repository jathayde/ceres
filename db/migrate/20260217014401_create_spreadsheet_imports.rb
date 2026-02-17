class CreateSpreadsheetImports < ActiveRecord::Migration[8.1]
  def change
    create_table :spreadsheet_imports do |t|
      t.string :original_filename, null: false
      t.integer :status, null: false, default: 0
      t.integer :total_rows, default: 0
      t.integer :parsed_rows, default: 0
      t.text :error_message
      t.jsonb :sheet_names, default: []
      t.timestamps
    end
  end
end
