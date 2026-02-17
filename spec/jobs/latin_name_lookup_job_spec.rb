require "rails_helper"

RSpec.describe LatinNameLookupJob, type: :job do
  let(:plant) { create(:plant, name: "Cherokee Purple", latin_name: nil) }

  describe "#perform" do
    let(:ai_response_json) do
      {
        latin_name: "Solanum lycopersicum 'Cherokee Purple'",
        category_latin_genus: "Solanum",
        category_latin_species: "lycopersicum"
      }.to_json
    end

    let(:mock_text_block) { instance_double(Anthropic::Models::TextBlock, text: ai_response_json) }
    let(:mock_response) { instance_double(Anthropic::Models::Message, content: [ mock_text_block ]) }

    let(:mock_messages) { instance_double("Anthropic::Resources::Messages") }
    let(:mock_client) { instance_double("Anthropic::Client", messages: mock_messages) }

    before do
      allow(Anthropic::Client).to receive(:new).and_return(mock_client)
      allow(mock_messages).to receive(:create).and_return(mock_response)
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    end

    it "updates the plant's latin_name" do
      described_class.perform_now(plant.id)
      expect(plant.reload.latin_name).to eq("Solanum lycopersicum 'Cherokee Purple'")
    end

    it "marks the latin_name as AI-populated" do
      described_class.perform_now(plant.id)
      expect(plant.reload.latin_name_ai_populated).to be true
    end

    it "updates category latin_genus when missing" do
      plant.plant_category.update!(latin_genus: nil)
      described_class.perform_now(plant.id)
      expect(plant.plant_category.reload.latin_genus).to eq("Solanum")
    end

    it "marks category latin_genus as AI-populated" do
      plant.plant_category.update!(latin_genus: nil)
      described_class.perform_now(plant.id)
      expect(plant.plant_category.reload.latin_genus_ai_populated).to be true
    end

    it "updates category latin_species when missing" do
      plant.plant_category.update!(latin_species: nil)
      described_class.perform_now(plant.id)
      expect(plant.plant_category.reload.latin_species).to eq("lycopersicum")
    end

    it "marks category latin_species as AI-populated" do
      plant.plant_category.update!(latin_species: nil)
      described_class.perform_now(plant.id)
      expect(plant.plant_category.reload.latin_species_ai_populated).to be true
    end

    it "does not overwrite existing category latin_genus" do
      plant.plant_category.update!(latin_genus: "Existing Genus")
      described_class.perform_now(plant.id)
      expect(plant.plant_category.reload.latin_genus).to eq("Existing Genus")
    end

    it "does not overwrite existing category latin_species" do
      plant.plant_category.update!(latin_species: "existing_species")
      described_class.perform_now(plant.id)
      expect(plant.plant_category.reload.latin_species).to eq("existing_species")
    end

    it "skips processing when plant already has a latin_name" do
      plant.update_columns(latin_name: "Already Set")
      described_class.perform_now(plant.id)
      expect(mock_messages).not_to have_received(:create)
    end

    it "broadcasts a Turbo Stream update" do
      described_class.perform_now(plant.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "plant_#{plant.id}_latin_name",
        target: "plant_latin_name",
        partial: "plants/latin_name",
        locals: { plant: plant.reload }
      )
    end

    it "calls the Anthropic API with correct parameters" do
      described_class.perform_now(plant.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 512
        )
      )
    end

    it "includes plant name in the prompt" do
      described_class.perform_now(plant.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          messages: [ hash_including(content: a_string_including("Cherokee Purple")) ]
        )
      )
    end

    context "with markdown code fences in response" do
      let(:ai_response_json) do
        "```json\n" + {
          latin_name: "Solanum lycopersicum",
          category_latin_genus: nil,
          category_latin_species: nil
        }.to_json + "\n```"
      end

      it "strips code fences and parses JSON correctly" do
        described_class.perform_now(plant.id)
        expect(plant.reload.latin_name).to eq("Solanum lycopersicum")
      end
    end

    context "when AI returns null for latin_name" do
      let(:ai_response_json) do
        {
          latin_name: nil,
          category_latin_genus: "Solanum",
          category_latin_species: "lycopersicum"
        }.to_json
      end

      it "does not update the plant's latin_name" do
        described_class.perform_now(plant.id)
        expect(plant.reload.latin_name).to be_nil
      end

      it "still updates category latin fields when missing" do
        plant.plant_category.update!(latin_genus: nil)
        described_class.perform_now(plant.id)
        expect(plant.plant_category.reload.latin_genus).to eq("Solanum")
      end
    end

    context "with API key configuration" do
      it "uses ANTHROPIC_API_KEY env var when available" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("test-key")

        described_class.perform_now(plant.id)

        expect(Anthropic::Client).to have_received(:new).with(api_key: "test-key")
      end
    end
  end

  describe "job enqueueing" do
    let(:plant_with_latin) { create(:plant, name: "Cherokee Purple", latin_name: "Already Set") }

    it "enqueues the job" do
      expect {
        described_class.perform_later(plant_with_latin.id)
      }.to have_enqueued_job(described_class).with(plant_with_latin.id)
    end

    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(plant_with_latin.id)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
