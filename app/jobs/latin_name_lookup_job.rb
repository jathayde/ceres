class LatinNameLookupJob < ApplicationJob
  queue_as :default

  def perform(plant_id)
    plant = Plant.find(plant_id)
    return if plant.latin_name.present?

    response = call_anthropic(plant)
    parsed = parse_response(response)
    save_latin_names(plant, parsed)
  end

  private

  def call_anthropic(plant)
    client = Anthropic::Client.new(
      api_key: api_key
    )

    client.messages.create(
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 512,
      messages: [
        { role: "user", content: build_prompt(plant) }
      ]
    )
  end

  def build_prompt(plant)
    category = plant.plant_category
    subcategory = plant.plant_subcategory

    <<~PROMPT
      You are a botanical expert. Given the following plant variety information, provide the correct Latin/botanical name.

      Common name: #{plant.name}
      Plant category: #{category.name}
      #{subcategory ? "Subcategory: #{subcategory.name}" : ""}
      #{category.latin_genus.present? ? "Category genus: #{category.latin_genus}" : ""}
      #{category.latin_species.present? ? "Category species: #{category.latin_species}" : ""}

      Respond with ONLY a valid JSON object (no markdown, no code fences) with these exact keys. Use null for any field you're unsure about.

      {
        "latin_name": "Full botanical name for this specific variety (e.g., 'Solanum lycopersicum' for tomato varieties)",
        "category_latin_genus": "The genus for the plant category (e.g., 'Solanum' for Tomato category)",
        "category_latin_species": "The species for the plant category (e.g., 'lycopersicum' for Tomato category)"
      }
    PROMPT
  end

  def parse_response(response)
    text = response.content.first.text
    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
    JSON.parse(text, symbolize_names: true)
  end

  def save_latin_names(plant, data)
    if data[:latin_name].present?
      plant.update!(
        latin_name: data[:latin_name],
        latin_name_ai_populated: true
      )
    end

    category = plant.plant_category
    update_category_latin(category, data)

    broadcast_update(plant)
  end

  def update_category_latin(category, data)
    attrs = {}

    if category.latin_genus.blank? && data[:category_latin_genus].present?
      attrs[:latin_genus] = data[:category_latin_genus]
      attrs[:latin_genus_ai_populated] = true
    end

    if category.latin_species.blank? && data[:category_latin_species].present?
      attrs[:latin_species] = data[:category_latin_species]
      attrs[:latin_species_ai_populated] = true
    end

    category.update!(attrs) if attrs.any?
  end

  def broadcast_update(plant)
    Turbo::StreamsChannel.broadcast_replace_to(
      "plant_#{plant.id}_latin_name",
      target: "plant_latin_name",
      partial: "plants/latin_name",
      locals: { plant: plant.reload }
    )
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
  end
end
