class SpreadsheetImportsController < ApplicationController
  before_action :set_import, only: %i[ show ]

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

  private

  def set_import
    @import = SpreadsheetImport.find(params[:id])
  end

  def file_param
    params.require(:spreadsheet_import).fetch(:file)
  end
end
