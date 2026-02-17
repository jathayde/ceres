require "rails_helper"

RSpec.describe GrowingGuideResearchJob, type: :job do
  let(:plant) { create(:plant, name: "Cherokee Purple", latin_name: "Solanum lycopersicum") }

  describe "#perform" do
    let(:ai_response_json) do
      {
        overview: "A popular heirloom tomato with deep purple-red skin.",
        soil_requirements: "Rich, well-drained soil with pH 6.0-6.8.",
        sun_exposure: "full_sun",
        water_needs: "moderate",
        spacing_inches: 24,
        row_spacing_inches: 36,
        planting_depth_inches: 0.25,
        germination_temp_min_f: 65,
        germination_temp_max_f: 85,
        germination_days_min: 7,
        germination_days_max: 14,
        growing_tips: "Stake or cage plants for support.",
        harvest_notes: "Harvest when fruit is deep purple-red.",
        seed_saving_notes: "Allow fruit to fully ripen on vine before saving seeds."
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

    it "creates a growing guide for the plant" do
      expect { described_class.perform_now(plant.id) }.to change(GrowingGuide, :count).by(1)
    end

    it "saves AI response fields to the growing guide" do
      described_class.perform_now(plant.id)
      guide = plant.reload.growing_guide

      expect(guide.overview).to eq("A popular heirloom tomato with deep purple-red skin.")
      expect(guide.soil_requirements).to eq("Rich, well-drained soil with pH 6.0-6.8.")
      expect(guide.sun_exposure).to eq("full_sun")
      expect(guide.water_needs).to eq("moderate")
      expect(guide.spacing_inches).to eq(24)
      expect(guide.row_spacing_inches).to eq(36)
      expect(guide.planting_depth_inches).to eq(0.25)
      expect(guide.germination_temp_min_f).to eq(65)
      expect(guide.germination_temp_max_f).to eq(85)
      expect(guide.germination_days_min).to eq(7)
      expect(guide.germination_days_max).to eq(14)
      expect(guide.growing_tips).to eq("Stake or cage plants for support.")
      expect(guide.harvest_notes).to eq("Harvest when fruit is deep purple-red.")
      expect(guide.seed_saving_notes).to eq("Allow fruit to fully ripen on vine before saving seeds.")
    end

    it "marks the guide as AI-generated with timestamp" do
      described_class.perform_now(plant.id)
      guide = plant.reload.growing_guide

      expect(guide.ai_generated).to be true
      expect(guide.ai_generated_at).to be_within(5.seconds).of(Time.current)
    end

    it "updates an existing growing guide" do
      existing_guide = create(:growing_guide, plant: plant, overview: "Old overview")

      described_class.perform_now(plant.id)
      existing_guide.reload

      expect(existing_guide.overview).to eq("A popular heirloom tomato with deep purple-red skin.")
      expect(existing_guide.ai_generated).to be true
    end

    it "broadcasts a Turbo Stream update" do
      described_class.perform_now(plant.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "plant_#{plant.id}_growing_guide",
        target: "growing_guide_section",
        partial: "plants/growing_guide",
        locals: { plant: plant, growing_guide: plant.reload.growing_guide }
      )
    end

    it "calls the Anthropic API with correct parameters" do
      described_class.perform_now(plant.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 2048
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

    it "includes latin name in the prompt when present" do
      described_class.perform_now(plant.id)

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          messages: [ hash_including(content: a_string_including("Solanum lycopersicum")) ]
        )
      )
    end

    context "with markdown code fences in response" do
      let(:ai_response_json) do
        "```json\n" + {
          overview: "Test overview",
          soil_requirements: nil,
          sun_exposure: "full_sun",
          water_needs: nil,
          spacing_inches: nil,
          row_spacing_inches: nil,
          planting_depth_inches: nil,
          germination_temp_min_f: nil,
          germination_temp_max_f: nil,
          germination_days_min: nil,
          germination_days_max: nil,
          growing_tips: nil,
          harvest_notes: nil,
          seed_saving_notes: nil
        }.to_json + "\n```"
      end

      it "strips code fences and parses JSON correctly" do
        described_class.perform_now(plant.id)
        guide = plant.reload.growing_guide
        expect(guide.overview).to eq("Test overview")
      end
    end

    context "with invalid enum value from AI" do
      let(:ai_response_json) do
        {
          overview: "Test overview",
          soil_requirements: nil,
          sun_exposure: "invalid_value",
          water_needs: "moderate",
          spacing_inches: nil,
          row_spacing_inches: nil,
          planting_depth_inches: nil,
          germination_temp_min_f: nil,
          germination_temp_max_f: nil,
          germination_days_min: nil,
          germination_days_max: nil,
          growing_tips: nil,
          harvest_notes: nil,
          seed_saving_notes: nil
        }.to_json
      end

      it "sets invalid enum values to nil" do
        described_class.perform_now(plant.id)
        guide = plant.reload.growing_guide
        expect(guide.sun_exposure).to be_nil
        expect(guide.water_needs).to eq("moderate")
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
    it "enqueues the job" do
      expect {
        described_class.perform_later(plant.id)
      }.to have_enqueued_job(described_class).with(plant.id)
    end

    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(plant.id)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
