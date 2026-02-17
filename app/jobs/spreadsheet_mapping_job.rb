class SpreadsheetMappingJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 20

  def perform(spreadsheet_import_id)
    @import = SpreadsheetImport.find(spreadsheet_import_id)
    @import.mapping!

    @existing_categories = load_existing_categories
    @existing_sources = load_existing_sources

    rows = @import.spreadsheet_import_rows.needs_mapping.order(:id)
    total = rows.count
    mapped = 0

    rows.in_batches(of: BATCH_SIZE) do |batch|
      batch_rows = batch.to_a
      map_batch(batch_rows)
      mapped += batch_rows.size
      @import.update!(mapped_rows: mapped)
      broadcast_status
    end

    detect_duplicates
    @import.mapped!
    broadcast_status
  rescue => e
    @import&.update!(status: :failed, error_message: "Mapping failed: #{e.message}")
    broadcast_status
    raise
  end

  private

  def load_existing_categories
    PlantCategory.includes(:plant_type, :plant_subcategories).map { |cat|
      {
        plant_type: cat.plant_type.name,
        category: cat.name,
        subcategories: cat.plant_subcategories.pluck(:name)
      }
    }
  end

  def load_existing_sources
    SeedSource.pluck(:name)
  end

  def map_batch(rows)
    response = call_anthropic(rows)
    mappings = parse_response(response)

    rows.each_with_index do |row, idx|
      mapping = mappings[idx]
      next unless mapping

      row.update!(
        mapped_plant_type_name: mapping[:plant_type],
        mapped_category_name: mapping[:category],
        mapped_subcategory_name: mapping[:subcategory].presence,
        mapped_source_name: mapping[:normalized_source].presence || row.seed_source_name,
        mapping_status: :ai_mapped,
        mapping_confidence: mapping[:confidence],
        ai_mapping_data: mapping,
        mapping_notes: mapping[:notes]
      )
    end
  end

  def call_anthropic(rows)
    client = Anthropic::Client.new(api_key: api_key)

    client.messages.create(
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 4096,
      messages: [
        { role: "user", content: build_prompt(rows) }
      ]
    )
  end

  def build_prompt(rows)
    rows_json = rows.map.with_index { |row, idx|
      {
        index: idx,
        variety_name: row.variety_name,
        source_name: row.seed_source_name,
        sheet: row.sheet_name,
        year: row.year_purchased,
        notes: row.notes
      }
    }

    <<~PROMPT
      You are a horticultural data expert helping classify seed inventory data. Given the following rows from a spreadsheet, map each to the correct plant taxonomy.

      ## Existing taxonomy in the database:
      #{@existing_categories.map { |c| "- #{c[:plant_type]} > #{c[:category]}#{c[:subcategories].any? ? " (subcategories: #{c[:subcategories].join(', ')})" : ""}" }.join("\n")}

      ## Existing seed sources in the database:
      #{@existing_sources.join(", ")}

      ## Rows to classify:
      ```json
      #{rows_json.to_json}
      ```

      For each row, determine:
      1. **plant_type**: Which PlantType this belongs to (must be one of: Vegetable, Grain, Herb, Flower, Cover Crop). Use the sheet name as a strong hint.
      2. **category**: Which PlantCategory this belongs to. Match to existing categories when possible. If no existing category fits, suggest a new one.
      3. **subcategory**: Which PlantSubcategory this belongs to (or null if none applies). Only use existing subcategories or suggest new ones when the variety clearly belongs to a known subdivision (e.g., "Bush Bean" → subcategory "Bush" under Bean category).
      4. **normalized_source**: The normalized seed source name. Match to existing sources when possible (handle abbreviations, misspellings, alternate names). If no match, return the cleaned-up name.
      5. **confidence**: A confidence score from 0.0 to 1.0 for the overall mapping.
      6. **notes**: Any notes about the mapping (e.g., "New category suggested", "Source name normalized from abbreviation").

      Respond with ONLY a valid JSON array (no markdown, no code fences). Each element corresponds to a row by index order:
      [
        {
          "index": 0,
          "plant_type": "Vegetable",
          "category": "Tomato",
          "subcategory": null,
          "normalized_source": "Johnny's Selected Seeds",
          "confidence": 0.95,
          "notes": null
        }
      ]
    PROMPT
  end

  def parse_response(response)
    text = response.content.first.text
    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
    JSON.parse(text, symbolize_names: true)
  end

  def detect_duplicates
    rows = @import.spreadsheet_import_rows.where.not(mapping_status: :rejected).order(:id)
    seen = {}

    rows.each do |row|
      key = normalize_duplicate_key(row)
      next if key.blank?

      if seen[key]
        row.update!(duplicate_of_row_id: seen[key].id, mapping_notes: [ row.mapping_notes, "Possible duplicate of row #{seen[key].row_number} (#{seen[key].sheet_name})" ].compact.join("; "))
      else
        seen[key] = row
      end
    end
  end

  def normalize_duplicate_key(row)
    name = (row.variety_name || row.mapped_category_name).to_s.downcase.strip.gsub(/\s+/, " ")
    return nil if name.blank?
    name
  end

  def broadcast_status
    Turbo::StreamsChannel.broadcast_replace_to(
      "spreadsheet_import_#{@import.id}",
      target: "import_status",
      partial: "spreadsheet_imports/status",
      locals: { import: @import.reload }
    )
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
  end
end
