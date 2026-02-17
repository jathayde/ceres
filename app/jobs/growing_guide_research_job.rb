class GrowingGuideResearchJob < ApplicationJob
  queue_as :default

  def perform(guideable_id, guideable_type)
    @guideable = guideable_type.constantize.find(guideable_id)
    response = call_anthropic(build_guide_prompt)
    parsed = parse_response(response)
    save_growing_guide(parsed)

    generate_variety_descriptions
  end

  private

  def call_anthropic(prompt)
    client = Anthropic::Client.new(
      api_key: api_key
    )

    client.messages.create(
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 2048,
      messages: [
        { role: "user", content: prompt }
      ]
    )
  end

  def taxonomy_context
    context_parts = []

    case @guideable
    when PlantSubcategory
      context_parts << @guideable.plant_category.plant_type.name
      context_parts << @guideable.plant_category.name
      context_parts << @guideable.name
    when PlantCategory
      context_parts << @guideable.plant_type.name
      context_parts << @guideable.name
    end

    context_parts.join(" > ")
  end

  def build_guide_prompt
    name = @guideable.name
    taxonomy = taxonomy_context

    <<~PROMPT
      You are a horticultural expert. Provide a structured growing guide for the following plant category.

      Plant category: #{name}
      Taxonomy: #{taxonomy}

      Respond with ONLY a valid JSON object (no markdown, no code fences) with these exact keys. Use null for any field you're unsure about. All text fields should be concise but informative.

      {
        "overview": "Brief 1-2 sentence description of this category of plants",
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
        "seed_saving_notes": "How to save seeds from this category"
      }
    PROMPT
  end

  def parse_response(response)
    text = response.content.first.text
    # Strip any markdown code fences if present
    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
    JSON.parse(text, symbolize_names: true)
  end

  def save_growing_guide(data)
    guide = @guideable.growing_guide || @guideable.build_growing_guide

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

    broadcast_guide_update(guide)
  end

  def safe_enum(value, valid_values)
    return nil if value.nil?
    valid_values.key?(value.to_s) ? value.to_s : nil
  end

  def broadcast_guide_update(guide)
    stream_name = "growing_guide_#{@guideable.class.name.underscore}_#{@guideable.id}"
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name,
      target: "growing_guide_section",
      partial: "plants/growing_guide",
      locals: { guideable: @guideable, growing_guide: guide }
    )
  end

  def generate_variety_descriptions
    plants = plants_for_guideable
    return if plants.empty?

    response = call_anthropic(build_variety_prompt(plants))
    descriptions = parse_response(response)

    plants.each do |plant|
      description = descriptions[plant.name.to_sym] || descriptions[plant.name]
      next unless description.present?

      plant.update!(
        variety_description: description,
        variety_description_ai_populated: true
      )

      broadcast_variety_update(plant)
    end
  end

  def plants_for_guideable
    case @guideable
    when PlantSubcategory
      @guideable.plants
    when PlantCategory
      @guideable.plants
    else
      Plant.none
    end
  end

  def build_variety_prompt(plants)
    variety_names = plants.map(&:name)
    taxonomy = taxonomy_context

    <<~PROMPT
      You are a horticultural expert. For each plant variety listed below, provide a brief 1-2 sentence description that highlights what makes this specific variety unique or notable (flavor, appearance, growth habit, history, etc.).

      Plant category: #{@guideable.name}
      Taxonomy: #{taxonomy}

      Varieties:
      #{variety_names.map { |n| "- #{n}" }.join("\n")}

      Respond with ONLY a valid JSON object (no markdown, no code fences) mapping each variety name exactly as given to its description string. Example format:
      {
        "Variety Name": "1-2 sentence description of this specific variety."
      }
    PROMPT
  end

  def broadcast_variety_update(plant)
    Turbo::StreamsChannel.broadcast_replace_to(
      "plant_#{plant.id}_variety_description",
      target: "plant_#{plant.id}_variety_description",
      partial: "plants/variety_description",
      locals: { plant: plant }
    )
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
  end
end
