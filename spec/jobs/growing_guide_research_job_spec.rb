require "rails_helper"

RSpec.describe GrowingGuideResearchJob, type: :job do
  let(:plant_category) { create(:plant_category, name: "Tomato") }

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

    let(:variety_response_json) do
      {
        "Cherokee Purple" => "A classic heirloom with dusky purple-pink fruits and rich, complex flavor.",
        "Brandywine" => "One of the most popular heirloom tomatoes, known for its large pink beefsteak fruits."
      }.to_json
    end

    let(:mock_guide_text_block) { instance_double(Anthropic::Models::TextBlock, text: ai_response_json) }
    let(:mock_guide_response) { instance_double(Anthropic::Models::Message, content: [ mock_guide_text_block ]) }

    let(:mock_variety_text_block) { instance_double(Anthropic::Models::TextBlock, text: variety_response_json) }
    let(:mock_variety_response) { instance_double(Anthropic::Models::Message, content: [ mock_variety_text_block ]) }

    let(:mock_messages) { instance_double("Anthropic::Resources::Messages") }
    let(:mock_client) { instance_double("Anthropic::Client", messages: mock_messages) }

    before do
      allow(Anthropic::Client).to receive(:new).and_return(mock_client)
      allow(mock_messages).to receive(:create).and_return(mock_guide_response, mock_variety_response)
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    end

    context "with a PlantCategory" do
      it "creates a growing guide for the category" do
        expect {
          described_class.perform_now(plant_category.id, "PlantCategory")
        }.to change(GrowingGuide, :count).by(1)
      end

      it "saves AI response fields to the growing guide" do
        described_class.perform_now(plant_category.id, "PlantCategory")
        guide = plant_category.reload.growing_guide

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
        described_class.perform_now(plant_category.id, "PlantCategory")
        guide = plant_category.reload.growing_guide

        expect(guide.ai_generated).to be true
        expect(guide.ai_generated_at).to be_within(5.seconds).of(Time.current)
      end

      it "updates an existing growing guide" do
        existing_guide = create(:growing_guide, plant_category: plant_category, overview: "Old overview")

        described_class.perform_now(plant_category.id, "PlantCategory")
        existing_guide.reload

        expect(existing_guide.overview).to eq("A popular heirloom tomato with deep purple-red skin.")
        expect(existing_guide.ai_generated).to be true
      end

      it "broadcasts a Turbo Stream update" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
          "growing_guide_plant_category_#{plant_category.id}",
          target: "growing_guide_section",
          partial: "plants/growing_guide",
          locals: { guideable: plant_category, growing_guide: plant_category.reload.growing_guide }
        )
      end

      it "includes category name in the prompt" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(mock_messages).to have_received(:create).with(
          hash_including(
            messages: [ hash_including(content: a_string_including("Tomato")) ]
          )
        ).at_least(:once)
      end
    end

    context "with a PlantSubcategory" do
      let(:plant_subcategory) { create(:plant_subcategory, name: "Cherry", plant_category: plant_category) }

      it "creates a growing guide for the subcategory" do
        expect {
          described_class.perform_now(plant_subcategory.id, "PlantSubcategory")
        }.to change(GrowingGuide, :count).by(1)
      end

      it "associates the guide with the subcategory" do
        described_class.perform_now(plant_subcategory.id, "PlantSubcategory")
        guide = plant_subcategory.reload.growing_guide

        expect(guide.plant_subcategory).to eq(plant_subcategory)
        expect(guide.plant_category).to be_nil
      end

      it "broadcasts with subcategory stream name" do
        described_class.perform_now(plant_subcategory.id, "PlantSubcategory")

        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
          "growing_guide_plant_subcategory_#{plant_subcategory.id}",
          target: "growing_guide_section",
          partial: "plants/growing_guide",
          locals: { guideable: plant_subcategory, growing_guide: plant_subcategory.reload.growing_guide }
        )
      end

      it "includes subcategory and category names in the prompt" do
        described_class.perform_now(plant_subcategory.id, "PlantSubcategory")

        expect(mock_messages).to have_received(:create).with(
          hash_including(
            messages: [ hash_including(content: a_string_including("Cherry").and(a_string_including("Tomato"))) ]
          )
        ).at_least(:once)
      end
    end

    it "calls the Anthropic API with correct parameters" do
      described_class.perform_now(plant_category.id, "PlantCategory")

      expect(mock_messages).to have_received(:create).with(
        hash_including(
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 2048
        )
      ).at_least(:once)
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
        described_class.perform_now(plant_category.id, "PlantCategory")
        guide = plant_category.reload.growing_guide
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
        described_class.perform_now(plant_category.id, "PlantCategory")
        guide = plant_category.reload.growing_guide
        expect(guide.sun_exposure).to be_nil
        expect(guide.water_needs).to eq("moderate")
      end
    end

    context "with API key configuration" do
      it "uses ANTHROPIC_API_KEY env var when available" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("test-key")

        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(Anthropic::Client).to have_received(:new).with(api_key: "test-key")
      end
    end

    context "variety descriptions" do
      let!(:plant_a) { create(:plant, name: "Cherokee Purple", plant_category: plant_category) }
      let!(:plant_b) { create(:plant, name: "Brandywine", plant_category: plant_category) }

      it "makes a second API call for variety descriptions" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(mock_messages).to have_received(:create).twice
      end

      it "updates plants with variety descriptions" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(plant_a.reload.variety_description).to eq("A classic heirloom with dusky purple-pink fruits and rich, complex flavor.")
        expect(plant_b.reload.variety_description).to eq("One of the most popular heirloom tomatoes, known for its large pink beefsteak fruits.")
      end

      it "sets variety_description_ai_populated to true" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(plant_a.reload.variety_description_ai_populated).to be true
        expect(plant_b.reload.variety_description_ai_populated).to be true
      end

      it "broadcasts variety description updates for each plant" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
          "plant_#{plant_a.id}_variety_description",
          target: "plant_#{plant_a.id}_variety_description",
          partial: "plants/variety_description",
          locals: { plant: plant_a }
        )
        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
          "plant_#{plant_b.id}_variety_description",
          target: "plant_#{plant_b.id}_variety_description",
          partial: "plants/variety_description",
          locals: { plant: plant_b }
        )
      end

      it "includes variety names in the prompt" do
        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(mock_messages).to have_received(:create).with(
          hash_including(
            messages: [ hash_including(
              content: a_string_including("Cherokee Purple").and(a_string_including("Brandywine"))
            ) ]
          )
        )
      end

      it "skips varieties not present in the API response" do
        plant_c = create(:plant, name: "Unknown Variety", plant_category: plant_category)

        described_class.perform_now(plant_category.id, "PlantCategory")

        expect(plant_c.reload.variety_description).to be_nil
        expect(plant_c.variety_description_ai_populated).to be false
      end

      it "skips variety descriptions when no plants exist" do
        plant_a.destroy!
        plant_b.destroy!

        described_class.perform_now(plant_category.id, "PlantCategory")

        # Only the guide API call, no variety call
        expect(mock_messages).to have_received(:create).once
      end

      context "with a PlantSubcategory" do
        let(:plant_subcategory) { create(:plant_subcategory, name: "Cherry", plant_category: plant_category) }
        let!(:sub_plant) { create(:plant, name: "Sun Gold", plant_category: plant_category, plant_subcategory: plant_subcategory) }

        let(:sub_variety_response_json) do
          { "Sun Gold" => "An exceptionally sweet orange cherry tomato, a garden favorite." }.to_json
        end

        before do
          mock_sub_variety_text = instance_double(Anthropic::Models::TextBlock, text: sub_variety_response_json)
          mock_sub_variety_response = instance_double(Anthropic::Models::Message, content: [ mock_sub_variety_text ])
          allow(mock_messages).to receive(:create).and_return(mock_guide_response, mock_sub_variety_response)
        end

        it "generates variety descriptions for subcategory plants" do
          described_class.perform_now(plant_subcategory.id, "PlantSubcategory")

          expect(sub_plant.reload.variety_description).to eq("An exceptionally sweet orange cherry tomato, a garden favorite.")
          expect(sub_plant.variety_description_ai_populated).to be true
        end
      end
    end
  end

  describe "job enqueueing" do
    it "enqueues the job" do
      expect {
        described_class.perform_later(plant_category.id, "PlantCategory")
      }.to have_enqueued_job(described_class).with(plant_category.id, "PlantCategory")
    end

    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(plant_category.id, "PlantCategory")
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
