require "rails_helper"

RSpec.describe SpreadsheetMappingJob, type: :job do
  let(:import) { create(:spreadsheet_import, :with_file, :parsed) }
  let!(:plant_type) { create(:plant_type, name: "Vegetable") }
  let!(:category) { create(:plant_category, plant_type: plant_type, name: "Tomato", expected_viability_years: 5) }
  let!(:source) { create(:seed_source, name: "Johnny's Selected Seeds") }

  let(:ai_response_body) do
    [
      {
        index: 0,
        plant_type: "Vegetable",
        category: "Tomato",
        subcategory: nil,
        normalized_source: "Johnny's Selected Seeds",
        confidence: 0.95,
        notes: nil
      },
      {
        index: 1,
        plant_type: "Vegetable",
        category: "Pepper",
        subcategory: nil,
        normalized_source: "Baker Creek Seeds",
        confidence: 0.88,
        notes: "New category suggested"
      }
    ]
  end

  let(:anthropic_response) do
    double("response", content: [ double("block", text: ai_response_body.to_json) ])
  end

  let(:anthropic_client) do
    double("client", messages: double("messages", create: anthropic_response))
  end

  before do
    allow(Anthropic::Client).to receive(:new).and_return(anthropic_client)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  describe "#perform" do
    let!(:row1) do
      create(:spreadsheet_import_row,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        seed_source_name: "Johnny's Seeds",
        year_purchased: 2023,
        sheet_name: "Vegetables")
    end

    let!(:row2) do
      create(:spreadsheet_import_row,
        spreadsheet_import: import,
        variety_name: "Habanero",
        seed_source_name: "Baker Creek",
        year_purchased: 2022,
        sheet_name: "Vegetables")
    end

    it "transitions import to mapping then mapped status" do
      described_class.new.perform(import.id)

      import.reload
      expect(import.status).to eq("mapped")
    end

    it "maps rows with AI-suggested data" do
      described_class.new.perform(import.id)

      row1.reload
      expect(row1.mapping_status).to eq("ai_mapped")
      expect(row1.mapped_plant_type_name).to eq("Vegetable")
      expect(row1.mapped_category_name).to eq("Tomato")
      expect(row1.mapped_source_name).to eq("Johnny's Selected Seeds")
      expect(row1.mapping_confidence).to eq(0.95)
    end

    it "maps second row correctly" do
      described_class.new.perform(import.id)

      row2.reload
      expect(row2.mapping_status).to eq("ai_mapped")
      expect(row2.mapped_category_name).to eq("Pepper")
      expect(row2.mapping_confidence).to eq(0.88)
      expect(row2.mapping_notes).to eq("New category suggested")
    end

    it "updates mapped_rows count on import" do
      described_class.new.perform(import.id)

      import.reload
      expect(import.mapped_rows).to eq(2)
    end

    it "broadcasts status updates" do
      described_class.new.perform(import.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).at_least(:once)
    end

    it "stores AI mapping data as JSON" do
      described_class.new.perform(import.id)

      row1.reload
      expect(row1.ai_mapping_data).to be_a(Hash)
      expect(row1.ai_mapping_data["plant_type"]).to eq("Vegetable")
    end
  end

  describe "duplicate detection" do
    let!(:row1) do
      create(:spreadsheet_import_row,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        seed_source_name: "Johnny's Seeds",
        year_purchased: 2023,
        sheet_name: "Vegetables")
    end

    let!(:row2) do
      create(:spreadsheet_import_row,
        spreadsheet_import: import,
        variety_name: "Cherokee Purple",
        seed_source_name: "Baker Creek",
        year_purchased: 2020,
        sheet_name: "Vegetables")
    end

    let(:ai_response_body) do
      [
        { index: 0, plant_type: "Vegetable", category: "Tomato", subcategory: nil, normalized_source: "Johnny's Seeds", confidence: 0.95, notes: nil },
        { index: 1, plant_type: "Vegetable", category: "Tomato", subcategory: nil, normalized_source: "Baker Creek", confidence: 0.90, notes: nil }
      ]
    end

    it "flags duplicate rows" do
      described_class.new.perform(import.id)

      row2.reload
      expect(row2.duplicate_of_row_id).to eq(row1.id)
      expect(row2.duplicate?).to be true
    end

    it "does not flag the first occurrence as duplicate" do
      described_class.new.perform(import.id)

      row1.reload
      expect(row1.duplicate_of_row_id).to be_nil
      expect(row1.duplicate?).to be false
    end
  end

  describe "error handling" do
    let!(:row) do
      create(:spreadsheet_import_row,
        spreadsheet_import: import,
        variety_name: "Test",
        sheet_name: "Vegetables")
    end

    it "marks import as failed on error" do
      allow(anthropic_client.messages).to receive(:create).and_raise(StandardError, "API error")

      expect {
        described_class.new.perform(import.id)
      }.to raise_error(StandardError)

      import.reload
      expect(import.status).to eq("failed")
      expect(import.error_message).to include("API error")
    end
  end

  describe "skips already-mapped rows" do
    let!(:mapped_row) do
      create(:spreadsheet_import_row, :accepted,
        spreadsheet_import: import,
        variety_name: "Already Mapped",
        sheet_name: "Vegetables")
    end

    let!(:unmapped_row) do
      create(:spreadsheet_import_row,
        spreadsheet_import: import,
        variety_name: "Not Mapped",
        sheet_name: "Vegetables")
    end

    let(:ai_response_body) do
      [ { index: 0, plant_type: "Vegetable", category: "Tomato", subcategory: nil, normalized_source: "Test", confidence: 0.90, notes: nil } ]
    end

    it "only processes unmapped rows" do
      described_class.new.perform(import.id)

      mapped_row.reload
      unmapped_row.reload

      expect(mapped_row.mapping_status).to eq("accepted")
      expect(unmapped_row.mapping_status).to eq("ai_mapped")
    end
  end
end
