class AddExecutionFieldsToSpreadsheetImports < ActiveRecord::Migration[8.1]
  def change
    add_column :spreadsheet_imports, :executed_rows, :integer, default: 0
    add_column :spreadsheet_imports, :import_report, :jsonb, default: {}
  end
end
