class SpreadsheetImport < ApplicationRecord
  has_one_attached :file
  has_many :spreadsheet_import_rows, dependent: :destroy

  enum :status, { pending: 0, parsing: 1, parsed: 2, failed: 3 }

  validates :original_filename, presence: true
  validate :file_is_xlsx, on: :create

  EXPECTED_SHEETS = [ "Vegetables", "Grains", "Herbs", "Flowers", "Cover Crops" ].freeze

  def parsed_percentage
    return 0 if total_rows.zero?
    (parsed_rows.to_f / total_rows * 100).round
  end

  def rows_by_sheet
    spreadsheet_import_rows.order(:row_number).group_by(&:sheet_name)
  end

  private

  def file_is_xlsx
    return errors.add(:file, "must be attached") unless file.attached?

    unless file.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      errors.add(:file, "must be an .xlsx file")
    end
  end
end
