class SpreadsheetImportRow < ApplicationRecord
  belongs_to :spreadsheet_import

  validates :sheet_name, presence: true
  validates :row_number, presence: true, uniqueness: { scope: [ :spreadsheet_import_id, :sheet_name ] }
end
