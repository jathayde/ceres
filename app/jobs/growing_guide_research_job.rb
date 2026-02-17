class GrowingGuideResearchJob < ApplicationJob
  queue_as :default

  def perform(plant_id)
    plant = Plant.find(plant_id)
    response = call_anthropic(plant)
    parsed = parse_response(response)
    save_growing_guide(plant, parsed)
  end

  private

  def call_anthropic(plant)
    client = Anthropic::Client.new(
      api_key: api_key
    )

    client.messages.create(
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 2048,
      messages: [
        { role: "user", content: build_prompt(plant) }
      ]
    )
  end

  def build_prompt(plant)
    category_context = plant.plant_category.name
    subcategory_context = plant.plant_subcategory&.name
    taxonomy = [ category_context, subcategory_context ].compact.join(" > ")

    <<~PROMPT
      You are a horticultural expert. Provide a structured growing guide for the following plant variety.

      Plant name: #{plant.name}
      #{plant.latin_name.present? ? "Latin name: #{plant.latin_name}" : ""}
      Category: #{taxonomy}

      Respond with ONLY a valid JSON object (no markdown, no code fences) with these exact keys. Use null for any field you're unsure about. All text fields should be concise but informative.

      {
        "overview": "Brief 1-2 sentence description of this variety",
        "soil_requirements": "Soil type, pH, amendments needed",
        "sun_exposure": "full_sun" or "partial_shade" or "full_shade",
        "water_needs": "low" or "moderate" or "high",
        "spacing_inches": integer or null,
        "row_spacing_inches": integer or null,
        "planting_depth_inches": number or null,
        "germination_temp_min_f": integer or null,
        "germination_temp_max_f": integer or null,
        "germination_days_min": integer or null,
        "germination_days_max": integer or null,
        "growing_tips": "Practical cultivation advice",
        "harvest_notes": "When and how to harvest",
        "seed_saving_notes": "How to save seeds from this variety"
      }
    PROMPT
  end

  def parse_response(response)
    text = response.content.first.text
    # Strip any markdown code fences if present
    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
    JSON.parse(text, symbolize_names: true)
  end

  def save_growing_guide(plant, data)
    guide = plant.growing_guide || plant.build_growing_guide

    guide.assign_attributes(
      overview: data[:overview],
      soil_requirements: data[:soil_requirements],
      sun_exposure: safe_enum(data[:sun_exposure], GrowingGuide.sun_exposures),
      water_needs: safe_enum(data[:water_needs], GrowingGuide.water_needs),
      spacing_inches: data[:spacing_inches],
      row_spacing_inches: data[:row_spacing_inches],
      planting_depth_inches: data[:planting_depth_inches],
      germination_temp_min_f: data[:germination_temp_min_f],
      germination_temp_max_f: data[:germination_temp_max_f],
      germination_days_min: data[:germination_days_min],
      germination_days_max: data[:germination_days_max],
      growing_tips: data[:growing_tips],
      harvest_notes: data[:harvest_notes],
      seed_saving_notes: data[:seed_saving_notes],
      ai_generated: true,
      ai_generated_at: Time.current
    )

    guide.save!

    broadcast_update(plant, guide)
  end

  def safe_enum(value, valid_values)
    return nil if value.nil?
    valid_values.key?(value.to_s) ? value.to_s : nil
  end

  def broadcast_update(plant, guide)
    Turbo::StreamsChannel.broadcast_replace_to(
      "plant_#{plant.id}_growing_guide",
      target: "growing_guide_section",
      partial: "plants/growing_guide",
      locals: { plant: plant, growing_guide: guide }
    )
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
  end
end
