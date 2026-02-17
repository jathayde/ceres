require "rails_helper"

RSpec.describe ViabilityDataEnrichmentJob, type: :job do
  let(:plant_category) { create(:plant_category, expected_viability_years: nil) }

  describe "#perform" do
    let(:ai_response_json) do
      {
        expected_viability_years: 5,
        source_notes: "Seeds typically remain viable for 4-6 years under proper storage conditions."
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

    it "updates the category's expected_viability_years" do
      described_class.perform_now(plant_category.id)
      expect(plant_category.reload.expected_viability_years).to eq(5)
    end

    it "marks the viability data as AI-populated" do
      described_class.perform_now(plant_category.id)
      expect(plant_category.reload.expected_viability_years_ai_populated).to be true
    end

    it "broadcasts a Turbo Stream update" do
      described_class.perform_now(plant_category.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "plant_category_#{plant_category.id}_viability",
        target: "plant_category_#{plant_category.id}_viability",
        partial: "plant_categories/viability_cell",
        locals: { category: plant_category }
      )
    end

    it "calls the Anthropic API with correct parameters" do
      described_class.perform_now(plant_category.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 512
        )
      )
    end

    it "includes category name in the prompt" do
      described_class.perform_now(plant_category.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          messages: [ hash_including(content: a_string_including(plant_category.name)) ]
        )
      )
    end

    it "includes plant type name in the prompt" do
      described_class.perform_now(plant_category.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          messages: [ hash_including(content: a_string_including(plant_category.plant_type.name)) ]
        )
      )
    end

    context "when category has latin genus" do
      before { plant_category.update!(latin_genus: "Phaseolus") }

      it "includes latin genus in the prompt" do
        described_class.perform_now(plant_category.id)

        expect(mock_messages).to have_received(:create).with(
          hash_including(
            messages: [ hash_including(content: a_string_including("Phaseolus")) ]
          )
        )
      end
    end

    context "with markdown code fences in response" do
      let(:ai_response_json) do
        "```json\n" + {
          expected_viability_years: 4,
          source_notes: "Typical viability for this species."
        }.to_json + "\n```"
      end

      it "strips code fences and parses JSON correctly" do
        described_class.perform_now(plant_category.id)
        expect(plant_category.reload.expected_viability_years).to eq(4)
      end
    end

    context "when AI returns null for expected_viability_years" do
      let(:ai_response_json) do
        {
          expected_viability_years: nil,
          source_notes: "Unable to determine viability for this category."
        }.to_json
      end

      it "does not update the category" do
        described_class.perform_now(plant_category.id)
        expect(plant_category.reload.expected_viability_years).to be_nil
      end

      it "does not mark as AI-populated" do
        described_class.perform_now(plant_category.id)
        expect(plant_category.reload.expected_viability_years_ai_populated).to be false
      end

      it "does not broadcast an update" do
        described_class.perform_now(plant_category.id)
        expect(Turbo::StreamsChannel).not_to have_received(:broadcast_replace_to)
      end
    end

    context "when category already has viability years" do
      before { plant_category.update!(expected_viability_years: 3) }

      it "overwrites with AI-suggested value" do
        described_class.perform_now(plant_category.id)
        expect(plant_category.reload.expected_viability_years).to eq(5)
      end

      it "marks as AI-populated" do
        described_class.perform_now(plant_category.id)
        expect(plant_category.reload.expected_viability_years_ai_populated).to be true
      end
    end

    context "with API key configuration" do
      it "uses ANTHROPIC_API_KEY env var when available" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("test-key")

        described_class.perform_now(plant_category.id)

        expect(Anthropic::Client).to have_received(:new).with(api_key: "test-key")
      end
    end
  end

  describe "job enqueueing" do
    it "enqueues the job" do
      expect {
        described_class.perform_later(plant_category.id)
      }.to have_enqueued_job(described_class).with(plant_category.id)
    end

    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(plant_category.id)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
