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

  describe "enums" do
    it { is_expected.to define_enum_for(:mapping_status).with_values(unmapped: 0, ai_mapped: 1, accepted: 2, modified: 3, rejected: 4) }
  end

  describe "scopes" do
    let(:import) { create(:spreadsheet_import, :with_file, :mapped) }

    describe ".needs_mapping" do
      it "returns only unmapped rows" do
        unmapped = create(:spreadsheet_import_row, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 2)
        create(:spreadsheet_import_row, :ai_mapped, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 3)

        expect(SpreadsheetImportRow.needs_mapping).to eq([ unmapped ])
      end
    end

    describe ".duplicates" do
      it "returns rows flagged as duplicates" do
        row1 = create(:spreadsheet_import_row, :ai_mapped, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 2)
        dup = create(:spreadsheet_import_row, :ai_mapped, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 3, duplicate_of_row_id: row1.id)

        expect(SpreadsheetImportRow.duplicates).to eq([ dup ])
      end
    end

    describe ".reviewable" do
      it "excludes rejected rows" do
        ai_mapped = create(:spreadsheet_import_row, :ai_mapped, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 2)
        create(:spreadsheet_import_row, :rejected, spreadsheet_import: import, sheet_name: "Vegetables", row_number: 3)

        expect(SpreadsheetImportRow.reviewable).to eq([ ai_mapped ])
      end
    end
  end

  describe "#duplicate?" do
    it "returns true when duplicate_of_row_id is present" do
      row = build(:spreadsheet_import_row, duplicate_of_row_id: 1)
      expect(row.duplicate?).to be true
    end

    it "returns false when duplicate_of_row_id is nil" do
      row = build(:spreadsheet_import_row)
      expect(row.duplicate?).to be false
    end
  end

  describe "#mapping_complete?" do
    it "returns true when plant type and category are mapped" do
      row = build(:spreadsheet_import_row, :ai_mapped)
      expect(row.mapping_complete?).to be true
    end

    it "returns false when category is missing" do
      row = build(:spreadsheet_import_row, mapped_plant_type_name: "Vegetable", mapped_category_name: nil)
      expect(row.mapping_complete?).to be false
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

    it "creates a valid ai_mapped record" do
      import = create(:spreadsheet_import, :with_file, :mapped)
      row = build(:spreadsheet_import_row, :ai_mapped, spreadsheet_import: import)
      expect(row).to be_valid
      expect(row.mapping_status).to eq("ai_mapped")
      expect(row.mapped_plant_type_name).to eq("Vegetable")
    end
  end
end
