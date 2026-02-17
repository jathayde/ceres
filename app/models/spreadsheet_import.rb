class SpreadsheetImport < ApplicationRecord
  has_one_attached :file
  has_many :spreadsheet_import_rows, dependent: :destroy

  enum :status, { pending: 0, parsing: 1, parsed: 2, failed: 3, mapping: 4, mapped: 5, executing: 6, executed: 7 }

  validates :original_filename, presence: true
  validate :file_is_xlsx, on: :create

  EXPECTED_SHEETS = [ "Vegetables", "Grains", "Herbs", "Flowers", "Cover Crops", "Trees" ].freeze

  def parsed_percentage
    return 0 if total_rows.zero?
    (parsed_rows.to_f / total_rows * 100).round
  end

  def mapped_percentage
    return 0 if total_rows.zero?
    (mapped_rows.to_f / total_rows * 100).round
  end

  def executed_percentage
    importable = importable_rows_count
    return 0 if importable.zero?
    (executed_rows.to_f / importable * 100).round
  end

  def rows_by_sheet
    spreadsheet_import_rows.order(:row_number).group_by(&:sheet_name)
  end

  def importable_rows
    spreadsheet_import_rows.where(mapping_status: [ :accepted, :modified ]).where(duplicate_of_row_id: nil)
  end

  def importable_rows_count
    importable_rows.count
  end

  def import_summary
    rows = importable_rows.includes(:spreadsheet_import)
    variety_names = rows.map { |r| normalize_variety_key(r) }.uniq
    source_names = rows.filter_map(&:mapped_source_name).map { |n| n.strip.downcase }.uniq
    category_names = rows.map { |r| [ r.mapped_plant_type_name, r.mapped_category_name ] }.uniq

    existing_sources = SeedSource.pluck(:name).map(&:downcase)
    new_sources = source_names.reject { |n| existing_sources.include?(n.downcase) }

    {
      plants_to_create: variety_names.size,
      purchases_to_create: rows.size,
      sources_to_create: new_sources.size,
      categories_to_check: category_names.size
    }
  end

  private

  def normalize_variety_key(row)
    [
      row.mapped_plant_type_name&.strip&.downcase,
      row.mapped_category_name&.strip&.downcase,
      row.mapped_subcategory_name&.strip&.downcase,
      row.variety_name&.strip&.downcase
    ]
  end

  def file_is_xlsx
    return errors.add(:file, "must be attached") unless file.attached?

    unless file.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      errors.add(:file, "must be an .xlsx file")
    end
  end
end
