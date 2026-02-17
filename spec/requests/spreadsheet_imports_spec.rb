require "rails_helper"

RSpec.describe "SpreadsheetImports", type: :request do
  describe "GET /spreadsheet_imports/new" do
    it "renders the upload form" do
      get new_spreadsheet_import_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Import Spreadsheet")
      expect(response.body).to include("Upload &amp; Parse")
    end
  end

  describe "POST /spreadsheet_imports" do
    it "creates an import and redirects to show" do
      tempfile = create_standard_test_xlsx

      expect {
        post spreadsheet_imports_path, params: {
          spreadsheet_import: {
            file: Rack::Test::UploadedFile.new(tempfile.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", true, original_filename: "seeds.xlsx")
          }
        }
      }.to change(SpreadsheetImport, :count).by(1)

      expect(response).to redirect_to(spreadsheet_import_path(SpreadsheetImport.last))
      follow_redirect!
      expect(response).to have_http_status(:success)
    end

    it "enqueues a parse job" do
      tempfile = create_standard_test_xlsx

      expect {
        post spreadsheet_imports_path, params: {
          spreadsheet_import: {
            file: Rack::Test::UploadedFile.new(tempfile.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", true, original_filename: "seeds.xlsx")
          }
        }
      }.to have_enqueued_job(SpreadsheetParseJob)
    end

    it "rejects non-xlsx files" do
      tempfile = Tempfile.new([ "test", ".csv" ])
      tempfile.write("name,source\nTomato,Baker Creek")
      tempfile.rewind

      post spreadsheet_imports_path, params: {
        spreadsheet_import: {
          file: Rack::Test::UploadedFile.new(tempfile.path, "text/csv", false, original_filename: "seeds.csv")
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(SpreadsheetImport.count).to eq(0)

      tempfile.close
      tempfile.unlink
    end
  end

  describe "GET /spreadsheet_imports/:id" do
    it "shows a pending import" do
      import = create(:spreadsheet_import, :with_file)
      get spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Pending")
    end

    it "shows a parsed import with rows" do
      import = create(:spreadsheet_import, :with_file, :parsed)
      create(:spreadsheet_import_row, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 2, variety_name: "Test Tomato")

      get spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Parsed")
      expect(response.body).to include("Test Tomato")
      expect(response.body).to include("Vegetables")
    end

    it "shows a failed import with error" do
      import = create(:spreadsheet_import, :with_file, :failed)
      get spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Failed")
      expect(response.body).to include("Invalid file format")
    end
  end
end
