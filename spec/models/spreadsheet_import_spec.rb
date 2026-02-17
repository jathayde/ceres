require "rails_helper"

RSpec.describe SpreadsheetImport, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:spreadsheet_import_rows).dependent(:destroy) }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:original_filename) }

    describe "file validation" do
      it "requires a file to be attached" do
        import = build(:spreadsheet_import)
        expect(import).not_to be_valid
        expect(import.errors[:file]).to include("must be attached")
      end

      it "requires the file to be an xlsx" do
        import = build(:spreadsheet_import)
        import.file.attach(
          io: StringIO.new("not xlsx"),
          filename: "test.csv",
          content_type: "text/csv"
        )
        expect(import).not_to be_valid
        expect(import.errors[:file]).to include("must be an .xlsx file")
      end

      it "accepts xlsx files" do
        import = build(:spreadsheet_import, :with_file)
        expect(import).to be_valid
      end
    end
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(pending: 0, parsing: 1, parsed: 2, failed: 3, mapping: 4, mapped: 5, executing: 6, executed: 7)
    }
  end

  describe "#parsed_percentage" do
    it "returns 0 when total_rows is 0" do
      import = build(:spreadsheet_import, total_rows: 0, parsed_rows: 0)
      expect(import.parsed_percentage).to eq(0)
    end

    it "calculates percentage correctly" do
      import = build(:spreadsheet_import, total_rows: 200, parsed_rows: 50)
      expect(import.parsed_percentage).to eq(25)
    end

    it "rounds to nearest integer" do
      import = build(:spreadsheet_import, total_rows: 3, parsed_rows: 1)
      expect(import.parsed_percentage).to eq(33)
    end
  end

  describe "#mapped_percentage" do
    it "returns 0 when total_rows is 0" do
      import = build(:spreadsheet_import, total_rows: 0, mapped_rows: 0)
      expect(import.mapped_percentage).to eq(0)
    end

    it "calculates percentage correctly" do
      import = build(:spreadsheet_import, total_rows: 200, mapped_rows: 100)
      expect(import.mapped_percentage).to eq(50)
    end
  end

  describe "#rows_by_sheet" do
    it "groups rows by sheet name" do
      import = create(:spreadsheet_import, :with_file, :parsed)
      create(:spreadsheet_import_row, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 2)
      create(:spreadsheet_import_row, spreadsheet_import: import, sheet_name: "Herbs", row_number: 2)
      create(:spreadsheet_import_row, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 3)

      grouped = import.rows_by_sheet
      expect(grouped.keys).to contain_exactly("Vegetables", "Herbs")
      expect(grouped["Vegetables"].size).to eq(2)
      expect(grouped["Herbs"].size).to eq(1)
    end
  end
end
