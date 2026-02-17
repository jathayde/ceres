class ViabilityDataEnrichmentJob < ApplicationJob
  queue_as :default

  def perform(plant_category_id)
    category = PlantCategory.find(plant_category_id)

    response = call_anthropic(category)
    parsed = parse_response(response)
    save_viability_data(category, parsed)
  end

  private

  def call_anthropic(category)
    client = Anthropic::Client.new(
      api_key: api_key
    )

    client.messages.create(
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 512,
      messages: [
        { role: "user", content: build_prompt(category) }
      ]
    )
  end

  def build_prompt(category)
    <<~PROMPT
      You are a horticultural expert specializing in seed viability and storage. Given the following plant category, provide the expected seed viability in years based on published horticultural sources.

      Plant category: #{category.name}
      Plant type: #{category.plant_type.name}
      #{category.latin_genus.present? ? "Latin genus: #{category.latin_genus}" : ""}
      #{category.latin_species.present? ? "Latin species: #{category.latin_species}" : ""}

      Seed viability years means how many years seeds of this type typically remain viable when stored under normal home conditions (cool, dry, dark).

      Respond with ONLY a valid JSON object (no markdown, no code fences) with these exact keys:

      {
        "expected_viability_years": integer (typically 1-10 years),
        "source_notes": "Brief explanation of the viability estimate and any relevant storage considerations"
      }
    PROMPT
  end

  def parse_response(response)
    text = response.content.first.text
    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")
    JSON.parse(text, symbolize_names: true)
  end

  def save_viability_data(category, data)
    return unless data[:expected_viability_years].present?

    category.update!(
      expected_viability_years: data[:expected_viability_years].to_i,
      expected_viability_years_ai_populated: true
    )

    broadcast_update(category)
  end

  def broadcast_update(category)
    Turbo::StreamsChannel.broadcast_replace_to(
      "plant_category_#{category.id}_viability",
      target: "plant_category_#{category.id}_viability",
      partial: "plant_categories/viability_cell",
      locals: { category: category }
    )
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
  end
end
