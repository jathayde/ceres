class AddMappingStatusToSpreadsheetImports < ActiveRecord::Migration[8.1]
  def change
    add_column :spreadsheet_imports, :mapped_rows, :integer, default: 0
  end
end
