class SpreadsheetImportsController < ApplicationController
  before_action :set_import, only: %i[ show review start_mapping update_row_mapping create_taxonomy confirm execute ]

  def new
    @import = SpreadsheetImport.new
  end

  def create
    @import = SpreadsheetImport.new(original_filename: file_param.original_filename)
    @import.file.attach(file_param)

    if @import.save
      SpreadsheetParseJob.perform_later(@import.id)
      redirect_to spreadsheet_import_path(@import), notice: "File uploaded successfully. Parsing in progress..."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @rows_by_sheet = @import.rows_by_sheet
  end

  def start_mapping
    unless @import.parsed? || @import.mapped?
      redirect_to spreadsheet_import_path(@import), alert: "Import must be parsed before mapping."
      return
    end

    SpreadsheetMappingJob.perform_later(@import.id)
    redirect_to review_spreadsheet_import_path(@import), notice: "AI mapping started. Results will appear as they are processed."
  end

  def review
    @rows = @import.spreadsheet_import_rows.reviewable.order(:sheet_name, :row_number)
    @plant_types = PlantType.order(:position).includes(plant_categories: :plant_subcategories)
    @seed_sources = SeedSource.order(:name)
    @stats = {
      total: @import.spreadsheet_import_rows.count,
      ai_mapped: @import.spreadsheet_import_rows.ai_mapped.count,
      accepted: @import.spreadsheet_import_rows.accepted.count,
      modified: @import.spreadsheet_import_rows.modified.count,
      rejected: @import.spreadsheet_import_rows.rejected.count,
      duplicates: @import.spreadsheet_import_rows.duplicates.count
    }
  end

  def update_row_mapping
    @row = @import.spreadsheet_import_rows.find(params[:row_id])

    case params[:action_type]
    when "accept"
      @row.update!(mapping_status: :accepted)
    when "reject"
      @row.update!(mapping_status: :rejected)
    when "modify"
      @row.update!(
        mapped_plant_type_name: params[:mapped_plant_type_name],
        mapped_category_name: params[:mapped_category_name],
        mapped_subcategory_name: params[:mapped_subcategory_name].presence,
        mapped_source_name: params[:mapped_source_name].presence,
        mapping_status: :modified
      )
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "import_row_#{@row.id}",
          partial: "spreadsheet_imports/review_row",
          locals: { row: @row, plant_types: load_plant_types, seed_sources: load_seed_sources }
        )
      end
      format.html { redirect_to review_spreadsheet_import_path(@import) }
    end
  end

  def create_taxonomy
    case params[:taxonomy_type]
    when "category"
      plant_type = PlantType.find_by!(name: params[:plant_type_name])
      PlantCategory.create!(
        plant_type: plant_type,
        name: params[:name]
      )
    when "subcategory"
      category = PlantCategory.find_by!(name: params[:category_name])
      PlantSubcategory.create!(
        plant_category: category,
        name: params[:name]
      )
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "taxonomy_options",
          partial: "spreadsheet_imports/taxonomy_options",
          locals: { plant_types: load_plant_types }
        )
      end
      format.html { redirect_to review_spreadsheet_import_path(@import), notice: "#{params[:taxonomy_type].capitalize} created." }
    end
  end

  def confirm
    unless @import.mapped?
      redirect_to spreadsheet_import_path(@import), alert: "Import must be mapped and reviewed before confirming."
      return
    end

    @summary = @import.import_summary
    @importable_rows = @import.importable_rows.order(:sheet_name, :row_number)
    @rows_by_sheet = @importable_rows.group_by(&:sheet_name)
  end

  def execute
    unless @import.mapped?
      redirect_to spreadsheet_import_path(@import), alert: "Import must be mapped before executing."
      return
    end

    SpreadsheetExecuteJob.perform_later(@import.id)
    redirect_to spreadsheet_import_path(@import), notice: "Import started. Progress will update automatically."
  end

  private

  def set_import
    @import = SpreadsheetImport.find(params[:id])
  end

  def file_param
    params.require(:spreadsheet_import).fetch(:file)
  end

  def load_plant_types
    PlantType.order(:position).includes(plant_categories: :plant_subcategories)
  end

  def load_seed_sources
    SeedSource.order(:name)
  end
end
