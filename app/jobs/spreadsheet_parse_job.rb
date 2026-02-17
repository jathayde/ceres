class SpreadsheetParseJob < ApplicationJob
  queue_as :default

  # Maps expected sheet names to PlantType names
  SHEET_TO_PLANT_TYPE = {
    "Vegetables" => "Vegetable",
    "Grains" => "Grain",
    "Herbs" => "Herb",
    "Flowers" => "Flower",
    "Cover Crops" => "Cover Crop"
  }.freeze

  # Common column name variations for each field.
  # Order matters: more specific patterns should be checked first.
  # Each entry is [field, pattern]. Checked in order; first match wins per column.
  COLUMN_MATCHERS = [
    [ :germination, /\b(germ|germination|germ\s*rate|germ\s*%)\b/i ],
    [ :lot, /\b(lot|lot\s*#|lot\s*number)\b/i ],
    [ :cost, /\b(cost|price|\$|paid)\b/i ],
    [ :quantity, /\b(qty|quantity|count|packets?|seeds?|weight|oz|ounce)\b/i ],
    [ :notes, /\b(notes?|comments?|remarks?|info)\b/i ],
    [ :source, /\b(source|supplier|vendor|company|purchased\s+from)\b/i ],
    [ :year, /\b(year|date|purchased|acquired|bought)\b/i ],
    [ :variety, /\b(variety|name|cultivar|type)\b/i ]
  ].freeze

  def perform(spreadsheet_import_id)
    import = SpreadsheetImport.find(spreadsheet_import_id)
    import.parsing!

    workbook = open_workbook(import)
    sheets = detect_sheets(workbook)
    import.update!(sheet_names: sheets)

    total = count_data_rows(workbook, sheets)
    import.update!(total_rows: total)

    parsed = 0
    sheets.each do |sheet_name|
      workbook.default_sheet = sheet_name
      parsed += parse_sheet(import, workbook, sheet_name)
      import.update!(parsed_rows: parsed)
    end

    import.parsed!
    broadcast_status(import)
  rescue => e
    import&.update!(status: :failed, error_message: e.message)
    broadcast_status(import) if import
    raise
  end

  private

  def open_workbook(import)
    tempfile = Tempfile.new([ "import", ".xlsx" ])
    tempfile.binmode
    tempfile.write(import.file.download)
    tempfile.rewind
    Roo::Spreadsheet.open(tempfile.path, extension: :xlsx)
  ensure
    tempfile&.close
  end

  def detect_sheets(workbook)
    workbook.sheets.select { |name|
      SHEET_TO_PLANT_TYPE.keys.any? { |expected| name.strip.downcase == expected.downcase }
    }
  end

  def count_data_rows(workbook, sheets)
    sheets.sum { |sheet_name|
      workbook.default_sheet = sheet_name
      [ workbook.last_row.to_i - 1, 0 ].max # subtract header row
    }
  end

  def parse_sheet(import, workbook, sheet_name)
    return 0 if workbook.last_row.nil? || workbook.last_row < 2

    header_row = workbook.row(1)
    column_map = map_columns(header_row)
    parsed_count = 0

    (2..workbook.last_row).each do |row_num|
      row_data = workbook.row(row_num)
      next if row_data.compact.empty? # skip blank rows

      raw_data = build_raw_data(header_row, row_data)
      gray = detect_gray_text(workbook, sheet_name, row_num)

      row_attrs = extract_row_data(row_data, column_map, gray)
      row_attrs[:sheet_name] = sheet_name
      row_attrs[:row_number] = row_num
      row_attrs[:raw_data] = raw_data

      import.spreadsheet_import_rows.create!(row_attrs)
      parsed_count += 1
    end

    parsed_count
  end

  def map_columns(header_row)
    mapping = {}
    header_row.each_with_index do |header, idx|
      next if header.nil?
      header_str = header.to_s.strip

      COLUMN_MATCHERS.each do |field, pattern|
        next if mapping.key?(field)
        if header_str.match?(pattern)
          mapping[field] = idx
          break
        end
      end
    end
    mapping
  end

  def build_raw_data(header_row, row_data)
    result = {}
    header_row.each_with_index do |header, idx|
      next if header.nil?
      key = header.to_s.strip
      result[key] = row_data[idx]&.to_s
    end
    result
  end

  def extract_row_data(row_data, column_map, gray)
    warnings = []

    variety_name = extract_string(row_data, column_map[:variety])
    source_name = extract_string(row_data, column_map[:source])

    year_result = extract_year(row_data, column_map[:year])
    year_purchased = year_result[:year]
    raw_date_value = year_result[:raw]
    warnings << year_result[:warning] if year_result[:warning]

    germ_result = extract_germination(row_data, column_map[:germination])
    germination_rate = germ_result[:rate]
    raw_germination_value = germ_result[:raw]
    warnings << germ_result[:warning] if germ_result[:warning]

    notes = extract_string(row_data, column_map[:notes])

    {
      variety_name: variety_name,
      seed_source_name: source_name,
      year_purchased: year_purchased,
      raw_date_value: raw_date_value,
      germination_rate: germination_rate,
      raw_germination_value: raw_germination_value,
      notes: notes,
      detected_used_up: gray,
      has_gray_text: gray,
      parse_warnings: warnings
    }
  end

  def extract_string(row_data, col_idx)
    return nil if col_idx.nil?
    val = row_data[col_idx]
    return nil if val.nil?
    val.to_s.strip.presence
  end

  def extract_year(row_data, col_idx)
    return { year: nil, raw: nil, warning: nil } if col_idx.nil?

    raw_val = row_data[col_idx]
    return { year: nil, raw: nil, warning: nil } if raw_val.nil?

    raw_str = raw_val.to_s.strip
    return { year: nil, raw: raw_str, warning: nil } if raw_str.blank?

    # Handle DateTime objects from Excel
    if raw_val.is_a?(DateTime) || raw_val.is_a?(Time) || raw_val.is_a?(Date)
      return { year: raw_val.year, raw: raw_str, warning: nil }
    end

    # Handle numeric (Excel sometimes stores years as floats)
    if raw_val.is_a?(Numeric)
      int_val = raw_val.to_i
      if int_val.between?(1990, 2100)
        return { year: int_val, raw: raw_str, warning: nil }
      end
    end

    # Try to parse year from string
    # Pattern: 4-digit year anywhere in the string
    if raw_str.match?(/\b(19|20)\d{2}\b/)
      year = raw_str.match(/\b((19|20)\d{2})\b/)[1].to_i
      warning = raw_str.match?(/\d{4}.*\d{4}/) ? "Multiple years found in '#{raw_str}', using first" : nil
      return { year: year, raw: raw_str, warning: warning }
    end

    # Try Ruby date parsing as last resort
    begin
      parsed = Date.parse(raw_str)
      return { year: parsed.year, raw: raw_str, warning: nil }
    rescue Date::Error
      # Can't parse
    end

    { year: nil, raw: raw_str, warning: "Could not parse year from '#{raw_str}'" }
  end

  def extract_germination(row_data, col_idx)
    return { rate: nil, raw: nil, warning: nil } if col_idx.nil?

    raw_val = row_data[col_idx]
    return { rate: nil, raw: nil, warning: nil } if raw_val.nil?

    raw_str = raw_val.to_s.strip
    return { rate: nil, raw: raw_str, warning: nil } if raw_str.blank?

    # Handle numeric values
    if raw_val.is_a?(Numeric)
      rate = raw_val.to_f
      # If > 1, assume percentage (e.g., 85 -> 0.85)
      rate = rate / 100.0 if rate > 1.0
      rate = [ [ rate, 0.0 ].max, 1.0 ].min
      return { rate: rate.round(4), raw: raw_str, warning: nil }
    end

    # Try to extract percentage from string like "85%", "0.85", etc.
    if raw_str.match?(/[\d.]+/)
      num = raw_str.scan(/[\d.]+/).first.to_f
      num = num / 100.0 if num > 1.0
      num = [ [ num, 0.0 ].max, 1.0 ].min
      return { rate: num.round(4), raw: raw_str, warning: nil }
    end

    { rate: nil, raw: raw_str, warning: "Could not parse germination rate from '#{raw_str}'" }
  end

  def detect_gray_text(workbook, sheet_name, row_num)
    # Roo doesn't provide direct cell formatting access for .xlsx files.
    # We'll check for common patterns that indicate used-up/gray seeds:
    # - Cells containing "used up", "gone", "empty", "depleted" etc.
    # Gray text detection requires the caxlsx or rubyXL gem for format access.
    # For now, we detect based on content patterns.
    row_data = workbook.row(row_num)
    row_text = row_data.compact.map(&:to_s).join(" ").downcase

    row_text.match?(/\b(used\s*up|depleted|gone|empty|finished|out\s*of|no\s*more)\b/)
  end

  def broadcast_status(import)
    Turbo::StreamsChannel.broadcast_replace_to(
      "spreadsheet_import_#{import.id}",
      target: "import_status",
      partial: "spreadsheet_imports/status",
      locals: { import: import }
    )
  end
end
