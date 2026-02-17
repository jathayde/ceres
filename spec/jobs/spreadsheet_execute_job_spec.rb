require "rails_helper"

RSpec.describe SpreadsheetExecuteJob, type: :job do
  let!(:plant_type) { create(:plant_type, name: "Vegetable") }
  let!(:category) { create(:plant_category, plant_type: plant_type, name: "Tomato") }
  let(:import) { create(:spreadsheet_import, :with_file, :mapped) }

  def create_accepted_row(attrs = {})
    create(:spreadsheet_import_row, :accepted, {
      spreadsheet_import: import,
      variety_name: "Cherokee Purple",
      sheet_name: "Vegetables",
      mapped_plant_type_name: "Vegetable",
      mapped_category_name: "Tomato",
      mapped_source_name: "Baker Creek",
      year_purchased: 2023
    }.merge(attrs))
  end

  describe "#perform" do
    it "transitions import status to executing then executed" do
      create_accepted_row

      described_class.new.perform(import.id)

      import.reload
      expect(import.status).to eq("executed")
    end

    it "skips non-mapped imports" do
      import.update!(status: :parsed)

      described_class.new.perform(import.id)

      import.reload
      expect(import.status).to eq("parsed")
    end

    it "creates plants from accepted rows" do
      create_accepted_row

      expect {
        described_class.new.perform(import.id)
      }.to change(Plant, :count).by(1)

      plant = Plant.last
      expect(plant.name).to eq("Cherokee Purple")
      expect(plant.plant_category).to eq(category)
      expect(plant.life_cycle).to eq("annual")
    end

    it "creates seed purchases for each row" do
      create_accepted_row

      expect {
        described_class.new.perform(import.id)
      }.to change(SeedPurchase, :count).by(1)

      purchase = SeedPurchase.last
      expect(purchase.year_purchased).to eq(2023)
      expect(purchase.seed_source.name).to eq("Baker Creek")
    end

    it "creates seed sources when they don't exist" do
      create_accepted_row(mapped_source_name: "New Supplier")

      expect {
        described_class.new.perform(import.id)
      }.to change(SeedSource, :count).by(1)

      expect(SeedSource.last.name).to eq("New Supplier")
    end

    it "deduplicates seed sources by name (case-insensitive)" do
      create(:seed_source, name: "Baker Creek")
      create_accepted_row(mapped_source_name: "baker creek")

      expect {
        described_class.new.perform(import.id)
      }.not_to change(SeedSource, :count)

      purchase = SeedPurchase.last
      expect(purchase.seed_source.name).to eq("Baker Creek")
    end

    it "consolidates duplicate varieties into one plant with multiple purchases" do
      create_accepted_row(row_number: 2, year_purchased: 2020)
      create_accepted_row(row_number: 3, year_purchased: 2022)

      expect {
        described_class.new.perform(import.id)
      }.to change(Plant, :count).by(1)
        .and change(SeedPurchase, :count).by(2)

      plant = Plant.find_by(name: "Cherokee Purple")
      expect(plant.seed_purchases.count).to eq(2)
      expect(plant.seed_purchases.pluck(:year_purchased)).to contain_exactly(2020, 2022)
    end

    it "creates categories when they don't exist" do
      create_accepted_row(mapped_category_name: "Pepper")

      expect {
        described_class.new.perform(import.id)
      }.to change(PlantCategory, :count).by(1)

      expect(PlantCategory.find_by(name: "Pepper").plant_type).to eq(plant_type)
    end

    it "creates subcategories when they don't exist" do
      create_accepted_row(mapped_subcategory_name: "Cherry")

      expect {
        described_class.new.perform(import.id)
      }.to change(PlantSubcategory, :count).by(1)

      expect(PlantSubcategory.find_by(name: "Cherry").plant_category).to eq(category)
    end

    it "sets used_up flag on rows detected as used up" do
      create_accepted_row(detected_used_up: true)

      described_class.new.perform(import.id)

      purchase = SeedPurchase.last
      expect(purchase.used_up).to be true
      expect(purchase.used_up_at).to eq(Date.current)
    end

    it "handles rows without a seed source" do
      create_accepted_row(mapped_source_name: nil, seed_source_name: nil)

      expect {
        described_class.new.perform(import.id)
      }.to change(SeedPurchase, :count).by(1)

      purchase = SeedPurchase.last
      expect(purchase.seed_source.name).to eq("Unknown")
    end

    it "uses modified rows as well as accepted" do
      create(:spreadsheet_import_row, :modified,
        spreadsheet_import: import,
        variety_name: "Brandywine",
        sheet_name: "Vegetables",
        row_number: 4,
        mapped_plant_type_name: "Vegetable",
        mapped_category_name: "Tomato",
        mapped_source_name: "Baker Creek",
        year_purchased: 2024)

      expect {
        described_class.new.perform(import.id)
      }.to change(Plant, :count).by(1)

      expect(Plant.last.name).to eq("Brandywine")
    end

    it "excludes rejected rows" do
      create(:spreadsheet_import_row, :rejected,
        spreadsheet_import: import,
        variety_name: "Rejected Variety",
        sheet_name: "Vegetables",
        row_number: 5,
        mapped_plant_type_name: "Vegetable",
        mapped_category_name: "Tomato")

      expect {
        described_class.new.perform(import.id)
      }.not_to change(Plant, :count)
    end

    it "excludes duplicate rows" do
      original = create_accepted_row(row_number: 2)
      create(:spreadsheet_import_row, :accepted,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        sheet_name: "Vegetables",
        row_number: 3,
        mapped_plant_type_name: "Vegetable",
        mapped_category_name: "Tomato",
        mapped_source_name: "Baker Creek",
        year_purchased: 2023,
        duplicate_of_row_id: original.id)

      expect {
        described_class.new.perform(import.id)
      }.to change(SeedPurchase, :count).by(1)
    end

    it "stores an import report" do
      create_accepted_row

      described_class.new.perform(import.id)

      import.reload
      report = import.import_report
      expect(report["plants_created"]).to eq(1)
      expect(report["purchases_created"]).to eq(1)
      expect(report["sources_created"]).to eq(1)
      expect(report["rows_skipped"]).to eq(0)
      expect(report["errors"]).to eq([])
    end

    it "updates executed_rows during processing" do
      create_accepted_row(row_number: 2)
      create_accepted_row(row_number: 3, variety_name: "Brandywine", year_purchased: 2024)

      described_class.new.perform(import.id)

      import.reload
      expect(import.executed_rows).to eq(2)
    end

    it "rolls back on failure (transaction)" do
      create_accepted_row(row_number: 2)
      # Create a row that will cause a failure — missing plant type
      create(:spreadsheet_import_row, :accepted,
        spreadsheet_import: import,
        variety_name: "Bad Row",
        sheet_name: "Vegetables",
        row_number: 3,
        mapped_plant_type_name: "Nonexistent",
        mapped_category_name: "Tomato",
        mapped_source_name: "Baker Creek",
        year_purchased: 2023)

      plant_count_before = Plant.count
      purchase_count_before = SeedPurchase.count

      expect {
        described_class.new.perform(import.id)
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(Plant.count).to eq(plant_count_before)
      expect(SeedPurchase.count).to eq(purchase_count_before)

      import.reload
      expect(import.status).to eq("failed")
      expect(import.error_message).to include("Import failed")
    end

    it "handles germination rate on purchases" do
      create_accepted_row(germination_rate: 0.85)

      described_class.new.perform(import.id)

      purchase = SeedPurchase.last
      expect(purchase.germination_rate).to eq(0.85)
    end

    it "uses current year when year_purchased is nil" do
      create_accepted_row(year_purchased: nil)

      described_class.new.perform(import.id)

      purchase = SeedPurchase.last
      expect(purchase.year_purchased).to eq(Date.current.year)
    end
  end
end
