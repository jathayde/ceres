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

    it "shows the AI Mapping button for parsed imports" do
      import = create(:spreadsheet_import, :with_file, :parsed)
      get spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Start AI Mapping")
    end

    it "shows the Review Mappings button for mapped imports" do
      import = create(:spreadsheet_import, :with_file, :mapped)
      get spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Review Mappings")
    end
  end

  describe "POST /spreadsheet_imports/:id/start_mapping" do
    it "enqueues a mapping job and redirects to review" do
      import = create(:spreadsheet_import, :with_file, :parsed)

      expect {
        post start_mapping_spreadsheet_import_path(import)
      }.to have_enqueued_job(SpreadsheetMappingJob)

      expect(response).to redirect_to(review_spreadsheet_import_path(import))
    end

    it "rejects non-parsed imports" do
      import = create(:spreadsheet_import, :with_file)

      post start_mapping_spreadsheet_import_path(import)
      expect(response).to redirect_to(spreadsheet_import_path(import))
    end
  end

  describe "GET /spreadsheet_imports/:id/review" do
    it "shows the review interface with mapped rows" do
      import = create(:spreadsheet_import, :with_file, :mapped)
      create(:spreadsheet_import_row, :ai_mapped,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        sheet_name: "Vegetables",
        row_number: 2)

      get review_spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Review Import Mappings")
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("AI Mapped")
    end

    it "shows stats summary" do
      import = create(:spreadsheet_import, :with_file, :mapped)
      create(:spreadsheet_import_row, :ai_mapped, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 2)
      create(:spreadsheet_import_row, :accepted, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 3)

      get review_spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("AI Mapped")
      expect(response.body).to include("Accepted")
    end

    it "shows duplicate badges" do
      import = create(:spreadsheet_import, :with_file, :mapped)
      row1 = create(:spreadsheet_import_row, :ai_mapped,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        sheet_name: "Vegetables",
        row_number: 2)
      create(:spreadsheet_import_row, :ai_mapped,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        sheet_name: "Vegetables",
        row_number: 3,
        duplicate_of_row_id: row1.id)

      get review_spreadsheet_import_path(import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Duplicate")
    end
  end

  describe "PATCH /spreadsheet_imports/:id/update_row_mapping" do
    let(:import) { create(:spreadsheet_import, :with_file, :mapped) }
    let!(:row) do
      create(:spreadsheet_import_row, :ai_mapped,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        sheet_name: "Vegetables",
        row_number: 2)
    end

    it "accepts a mapping" do
      patch update_row_mapping_spreadsheet_import_path(import, row_id: row.id, action_type: "accept")

      row.reload
      expect(row.mapping_status).to eq("accepted")
      expect(response).to redirect_to(review_spreadsheet_import_path(import))
    end

    it "rejects a mapping" do
      patch update_row_mapping_spreadsheet_import_path(import, row_id: row.id, action_type: "reject")

      row.reload
      expect(row.mapping_status).to eq("rejected")
    end

    it "modifies a mapping" do
      patch update_row_mapping_spreadsheet_import_path(import,
        row_id: row.id,
        action_type: "modify",
        mapped_plant_type_name: "Herb",
        mapped_category_name: "Basil",
        mapped_subcategory_name: "",
        mapped_source_name: "New Source"
      )

      row.reload
      expect(row.mapping_status).to eq("modified")
      expect(row.mapped_plant_type_name).to eq("Herb")
      expect(row.mapped_category_name).to eq("Basil")
      expect(row.mapped_subcategory_name).to be_nil
      expect(row.mapped_source_name).to eq("New Source")
    end
  end

  describe "POST /spreadsheet_imports/:id/create_taxonomy" do
    let(:import) { create(:spreadsheet_import, :with_file, :mapped) }

    it "creates a new category" do
      plant_type = create(:plant_type, name: "Vegetable")

      expect {
        post create_taxonomy_spreadsheet_import_path(import,
          taxonomy_type: "category",
          plant_type_name: "Vegetable",
          name: "Artichoke"
        )
      }.to change(PlantCategory, :count).by(1)

      expect(PlantCategory.last.name).to eq("Artichoke")
      expect(PlantCategory.last.plant_type).to eq(plant_type)
    end

    it "creates a new subcategory" do
      plant_type = create(:plant_type, name: "Vegetable")
      category = create(:plant_category, plant_type: plant_type, name: "Bean")

      expect {
        post create_taxonomy_spreadsheet_import_path(import,
          taxonomy_type: "subcategory",
          category_name: "Bean",
          name: "Lima"
        )
      }.to change(PlantSubcategory, :count).by(1)

      expect(PlantSubcategory.last.name).to eq("Lima")
      expect(PlantSubcategory.last.plant_category).to eq(category)
    end
  end
end
