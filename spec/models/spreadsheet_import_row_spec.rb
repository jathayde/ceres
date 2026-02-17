require "rails_helper"

RSpec.describe SpreadsheetImportRow, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:spreadsheet_import) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:sheet_name) }
    it { is_expected.to validate_presence_of(:row_number) }

    describe "row_number uniqueness scoped to import and sheet" do
      subject { create(:spreadsheet_import_row, spreadsheet_import: create(:spreadsheet_import, :with_file, :parsed)) }

      it { is_expected.to validate_uniqueness_of(:row_number).scoped_to([ :spreadsheet_import_id, :sheet_name ]) }
    end
  end

  describe "factory" do
    it "creates a valid record" do
      import = create(:spreadsheet_import, :with_file, :parsed)
      row = build(:spreadsheet_import_row, spreadsheet_import: import)
      expect(row).to be_valid
    end

    it "creates a valid used_up record" do
      import = create(:spreadsheet_import, :with_file, :parsed)
      row = build(:spreadsheet_import_row, :used_up, spreadsheet_import: import)
      expect(row).to be_valid
      expect(row.detected_used_up).to be true
      expect(row.has_gray_text).to be true
    end

    it "creates a valid record with germination data" do
      import = create(:spreadsheet_import, :with_file, :parsed)
      row = build(:spreadsheet_import_row, :with_germination, spreadsheet_import: import)
      expect(row).to be_valid
      expect(row.germination_rate).to eq(0.85)
    end
  end
end
