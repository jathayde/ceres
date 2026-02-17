class AddQuantityToSpreadsheetImportRows < ActiveRecord::Migration[8.1]
  def change
    add_column :spreadsheet_import_rows, :quantity, :integer, default: 1
  end
end
