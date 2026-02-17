require "rails_helper"

RSpec.describe SpreadsheetParseJob, type: :job do
  def create_import_with_xlsx(tempfile)
    import = SpreadsheetImport.new(original_filename: "test.xlsx")
    import.file.attach(
      io: File.open(tempfile.path),
      filename: "test.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    import.save!
    import
  end

  describe "#perform" do
    it "parses a standard multi-sheet xlsx file" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)
      import.reload

      expect(import.status).to eq("parsed")
      expect(import.sheet_names).to contain_exactly("Vegetables", "Herbs", "Grains", "Flowers", "Cover Crops")
      expect(import.spreadsheet_import_rows.count).to eq(9)
      expect(import.parsed_rows).to eq(9)
    end

    it "parses variety names correctly" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      veg_rows = import.spreadsheet_import_rows.where(sheet_name: "Vegetables").order(:row_number)
      expect(veg_rows.first.variety_name).to eq("Cherokee Purple Tomato")
      expect(veg_rows.second.variety_name).to eq("Sugar Snap Pea")
    end

    it "parses seed source names correctly" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      veg_rows = import.spreadsheet_import_rows.where(sheet_name: "Vegetables").order(:row_number)
      expect(veg_rows.first.seed_source_name).to eq("Baker Creek")
      expect(veg_rows.second.seed_source_name).to eq("Johnny's Seeds")
    end

    it "parses year from integer values" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Cherokee Purple Tomato")
      expect(row.year_purchased).to eq(2023)
    end

    it "parses year from string values" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Genovese Basil")
      expect(row.year_purchased).to eq(2022)
    end

    it "parses year from compound date strings" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Italian Parsley")
      expect(row.year_purchased).to eq(2023)
    end

    it "parses germination rate from decimal values" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Cherokee Purple Tomato")
      expect(row.germination_rate).to eq(0.92)
    end

    it "parses germination rate from percentage strings" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Genovese Basil")
      expect(row.germination_rate).to eq(0.85)
    end

    it "converts germination percentages > 1 to decimal" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Mammoth Sunflower")
      expect(row.germination_rate).to eq(0.95)
    end

    it "detects used-up rows from content patterns" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Old Bean")
      expect(row.detected_used_up).to be true
      expect(row.has_gray_text).to be true
    end

    it "stores raw data as JSON" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Cherokee Purple Tomato")
      expect(row.raw_data).to be_a(Hash)
      expect(row.raw_data.keys).to include("Variety")
    end

    it "handles inconsistent column layouts across tabs" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      # Herbs tab uses "Name" instead of "Variety" and "Supplier" instead of "Source"
      herb_row = import.spreadsheet_import_rows.find_by(variety_name: "Genovese Basil")
      expect(herb_row).to be_present
      expect(herb_row.seed_source_name).to eq("Baker Creek")

      # Flowers tab uses "Cultivar" instead of "Variety" and "Purchased From" instead of "Source"
      flower_row = import.spreadsheet_import_rows.find_by(variety_name: "Mammoth Sunflower")
      expect(flower_row).to be_present
      expect(flower_row.seed_source_name).to eq("Baker Creek")
    end

    it "preserves notes from the spreadsheet" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Cherokee Purple Tomato")
      expect(row.notes).to eq("Great heirloom")
    end

    it "sets total_rows and parsed_rows" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)
      import.reload

      expect(import.total_rows).to eq(9)
      expect(import.parsed_rows).to eq(9)
    end

    it "handles empty sheets gracefully" do
      tempfile = create_test_xlsx(sheets: {
        "Vegetables" => {
          headers: [ "Variety", "Source", "Year" ],
          rows: []
        }
      })
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)
      import.reload

      expect(import.status).to eq("parsed")
      expect(import.spreadsheet_import_rows.count).to eq(0)
    end

    it "skips sheets not matching expected names" do
      tempfile = create_test_xlsx(sheets: {
        "Vegetables" => {
          headers: [ "Variety", "Source", "Year" ],
          rows: [ [ "Tomato", "Baker Creek", 2023 ] ]
        },
        "Random Sheet" => {
          headers: [ "Something", "Else" ],
          rows: [ [ "Data", "Here" ] ]
        }
      })
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)
      import.reload

      expect(import.sheet_names).to eq([ "Vegetables" ])
      expect(import.spreadsheet_import_rows.count).to eq(1)
    end

    it "marks import as failed on error" do
      import = create(:spreadsheet_import, :with_file)

      # The fake file content won't parse as xlsx
      expect {
        described_class.new.perform(import.id)
      }.to raise_error(Zip::Error)

      import.reload
      expect(import.status).to eq("failed")
      expect(import.error_message).to be_present
    end

    it "handles nil germination values" do
      tempfile = create_standard_test_xlsx
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.find_by(variety_name: "Sugar Snap Pea")
      expect(row.germination_rate).to be_nil
    end
  end

  describe "column mapping" do
    it "maps varied column names to correct fields" do
      tempfile = create_test_xlsx(sheets: {
        "Vegetables" => {
          headers: [ "Cultivar Name", "Purchased From", "Date Purchased", "Germ Rate", "Remarks" ],
          rows: [
            [ "Big Boy Tomato", "Burpee", 2022, 0.90, "Classic hybrid" ]
          ]
        }
      })
      import = create_import_with_xlsx(tempfile)

      described_class.new.perform(import.id)

      row = import.spreadsheet_import_rows.first
      expect(row.variety_name).to eq("Big Boy Tomato")
      expect(row.seed_source_name).to eq("Burpee")
      expect(row.year_purchased).to eq(2022)
      expect(row.germination_rate).to eq(0.90)
      expect(row.notes).to eq("Classic hybrid")
    end
  end
end
