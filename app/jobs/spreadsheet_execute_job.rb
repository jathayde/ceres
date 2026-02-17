class SpreadsheetExecuteJob < ApplicationJob
  queue_as :default

  def perform(import_id)
    @import = SpreadsheetImport.find(import_id)
    return unless @import.mapped?

    @import.update!(status: :executing, executed_rows: 0, import_report: {})
    broadcast_status

    @report = {
      plants_created: 0,
      purchases_created: 0,
      sources_created: 0,
      categories_created: 0,
      subcategories_created: 0,
      rows_skipped: 0,
      errors: []
    }

    rows = @import.importable_rows.order(:sheet_name, :row_number)

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        import_row(row)
        @import.update!(executed_rows: index + 1)
        broadcast_status if (index + 1) % 5 == 0
      end
    end

    @import.update!(
      status: :executed,
      import_report: @report
    )
    broadcast_status
  rescue => e
    @import&.update(
      status: :failed,
      error_message: "Import failed: #{e.message}",
      import_report: @report || {}
    )
    broadcast_status
    raise
  end

  private

  def import_row(row)
    source = find_or_create_source(row)
    plant_type = find_plant_type(row)
    category = find_or_create_category(row, plant_type)
    subcategory = find_or_create_subcategory(row, category)
    plant = find_or_create_plant(row, category, subcategory)
    create_purchase(row, plant, source)
  rescue => e
    @report[:errors] << { row_id: row.id, row_number: row.row_number, sheet: row.sheet_name, variety: row.variety_name, error: e.message }
    @report[:rows_skipped] += 1
    raise
  end

  def find_or_create_source(row)
    return nil if row.mapped_source_name.blank?

    source_name = row.mapped_source_name.strip
    source = SeedSource.find_by("LOWER(name) = ?", source_name.downcase)

    unless source
      source = SeedSource.create!(name: source_name)
      @report[:sources_created] += 1
    end

    source
  end

  def find_plant_type(row)
    PlantType.find_by!(name: row.mapped_plant_type_name.strip)
  end

  def find_or_create_category(row, plant_type)
    category_name = row.mapped_category_name.strip
    category = plant_type.plant_categories.find_by("LOWER(name) = ?", category_name.downcase)

    unless category
      category = plant_type.plant_categories.create!(name: category_name)
      @report[:categories_created] += 1
    end

    category
  end

  def find_or_create_subcategory(row, category)
    return nil if row.mapped_subcategory_name.blank?

    subcategory_name = row.mapped_subcategory_name.strip
    subcategory = category.plant_subcategories.find_by("LOWER(name) = ?", subcategory_name.downcase)

    unless subcategory
      subcategory = category.plant_subcategories.create!(name: subcategory_name)
      @report[:subcategories_created] += 1
    end

    subcategory
  end

  def find_or_create_plant(row, category, subcategory)
    variety_name = row.variety_name.strip
    plant = category.plants.find_by("LOWER(name) = ?", variety_name.downcase)

    if plant
      # Update subcategory if it was nil and we now have one
      plant.update!(plant_subcategory: subcategory) if subcategory && plant.plant_subcategory.nil?
    else
      plant = category.plants.create!(
        name: variety_name,
        plant_subcategory: subcategory,
        life_cycle: :annual,
        notes: row.notes.presence
      )
      @report[:plants_created] += 1
    end

    plant
  end

  def create_purchase(row, plant, source)
    year = row.year_purchased || Date.current.year

    purchase_attrs = {
      plant: plant,
      year_purchased: year,
      germination_rate: row.germination_rate,
      packet_count: row.quantity || 1,
      used_up: row.detected_used_up?,
      used_up_at: row.detected_used_up? ? Date.current : nil
    }

    purchase_attrs[:seed_source] = source if source
    purchase_attrs[:notes] = row.notes if row.notes.present?

    # If no source, create a default "Unknown" source
    unless purchase_attrs[:seed_source]
      purchase_attrs[:seed_source] = SeedSource.find_or_create_by!(name: "Unknown")
      @report[:sources_created] += 1 unless SeedSource.where(name: "Unknown").count > 1
    end

    SeedPurchase.create!(purchase_attrs)
    @report[:purchases_created] += 1
  end

  def broadcast_status
    Turbo::StreamsChannel.broadcast_replace_to(
      "spreadsheet_import_#{@import.id}",
      target: "import_status",
      partial: "spreadsheet_imports/status",
      locals: { import: @import }
    )
  end
end
