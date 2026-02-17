class SpreadsheetImportRow < ApplicationRecord
  belongs_to :spreadsheet_import
  belongs_to :duplicate_of, class_name: "SpreadsheetImportRow", optional: true

  enum :mapping_status, { unmapped: 0, ai_mapped: 1, accepted: 2, modified: 3, rejected: 4 }

  validates :sheet_name, presence: true
  validates :row_number, presence: true, uniqueness: { scope: [ :spreadsheet_import_id, :sheet_name ] }

  scope :needs_mapping, -> { where(mapping_status: :unmapped) }
  scope :duplicates, -> { where.not(duplicate_of_row_id: nil) }
  scope :reviewable, -> { where.not(mapping_status: :rejected) }

  def duplicate?
    duplicate_of_row_id.present?
  end

  def mapping_complete?
    mapped_plant_type_name.present? && mapped_category_name.present?
  end
end
