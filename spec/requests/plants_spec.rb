require "rails_helper"

RSpec.describe "Plants", type: :request do
  let!(:plant_type) { create(:plant_type) }
  let!(:plant_category) { create(:plant_category, plant_type: plant_type) }
  let!(:plant_subcategory) { create(:plant_subcategory, plant_category: plant_category) }

  describe "GET /plants" do
    it "returns a successful response" do
      get plants_path
      expect(response).to have_http_status(:ok)
    end

    it "displays plants" do
      create(:plant, name: "Cherokee Purple", plant_category: plant_category)
      get plants_path
      expect(response.body).to include("Cherokee Purple")
    end

    it "displays the plant category" do
      plant = create(:plant, plant_category: plant_category)
      get plants_path
      expect(response.body).to include(plant_category.name)
    end

    it "displays heirloom badge for heirloom plants" do
      create(:plant, name: "Brandywine", plant_category: plant_category, heirloom: true)
      get plants_path
      expect(response.body).to include("Heirloom")
    end
  end

  describe "GET /plants/:id (show)" do
    let!(:plant) do
      create(:plant,
        name: "Cherokee Purple",
        plant_category: plant_category,
        plant_subcategory: plant_subcategory,
        latin_name: "Solanum lycopersicum",
        heirloom: true,
        life_cycle: :annual,
        winter_hardy: :tender,
        days_to_harvest_min: 75,
        days_to_harvest_max: 85,
        planting_seasons: %w[Spring Summer],
        notes: "Great heirloom tomato")
    end

    it "redirects to inventory variety URL with 301" do
      get plant_path(plant)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(inventory_subcategory_variety_path(
        plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug
      ))
    end

    it "redirects plant without subcategory to variety URL" do
      plant_no_sub = create(:plant, name: "Roma", plant_category: plant_category, plant_subcategory: nil)
      get plant_path(plant_no_sub)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(inventory_variety_path(
        plant_type.slug, plant_category.slug, plant_no_sub.slug
      ))
    end
  end

  describe "plant detail via inventory URL" do
    let!(:plant) do
      create(:plant,
        name: "Cherokee Purple",
        plant_category: plant_category,
        plant_subcategory: plant_subcategory,
        latin_name: "Solanum lycopersicum",
        heirloom: true,
        life_cycle: :annual,
        winter_hardy: :tender,
        days_to_harvest_min: 75,
        days_to_harvest_max: 85,
        planting_seasons: %w[Spring Summer],
        notes: "Great heirloom tomato")
    end

    it "returns a successful response" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response).to have_http_status(:ok)
    end

    it "displays the plant name and latin name" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Solanum lycopersicum")
    end

    it "displays taxonomy breadcrumb" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response.body).to include(plant_type.name)
      expect(response.body).to include(plant_category.name)
      expect(response.body).to include(plant_subcategory.name)
    end

    it "displays plant metadata" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response.body).to include("Annual")
      expect(response.body).to include("Tender")
      expect(response.body).to include("75")
      expect(response.body).to include("85")
      expect(response.body).to include("Spring")
      expect(response.body).to include("Summer")
    end

    it "displays heirloom badge" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response.body).to include("Heirloom")
    end

    it "displays plant notes" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response.body).to include("Great heirloom tomato")
    end

    it "displays Edit Plant and Add Purchase links" do
      get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
      expect(response.body).to include("Edit Plant")
      expect(response.body).to include("Add Purchase")
    end

    context "with seed purchases" do
      let!(:seed_source) { create(:seed_source, name: "Baker Creek", url: "https://rareseeds.com") }
      let!(:purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: 2024, lot_number: "LOT-123", cost_cents: 350, seed_count: 50) }

      it "displays seed purchase details" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("Baker Creek")
        expect(response.body).to include("2024")
        expect(response.body).to include("LOT-123")
        expect(response.body).to include("$3.50")
        expect(response.body).to include("50 seeds")
      end

      it "displays seed source as a link when URL present" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("https://rareseeds.com")
      end

      it "displays viability badge on purchases" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("Viable")
      end
    end

    context "with used-up purchase" do
      let!(:seed_source) { create(:seed_source, name: "Test Source") }
      let!(:used_purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: 2020, used_up: true) }

      it "displays used-up purchases with dimmed styling" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("opacity-50")
      end

      it "shows Mark Active button for used-up purchases" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("Mark Active")
      end
    end

    context "without seed purchases" do
      it "shows empty state message" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("No seed purchases yet")
      end
    end

    context "with variety description" do
      it "displays variety description when present" do
        plant.update!(variety_description: "A classic heirloom with rich flavor.", variety_description_ai_populated: true)
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("A classic heirloom with rich flavor.")
        expect(response.body).to include("About This Variety")
      end

      it "displays AI badge when variety_description_ai_populated" do
        plant.update!(variety_description: "AI-generated description.", variety_description_ai_populated: true)
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("AI-suggested")
      end

      it "does not display variety description section when blank" do
        plant.update!(variety_description: nil)
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).not_to include("About This Variety")
      end
    end

    context "with growing guide" do
      let!(:growing_guide) { create(:growing_guide, plant_category: plant_category, sun_exposure: :full_sun, water_needs: :moderate, spacing_inches: 24, overview: "A classic heirloom tomato") }

      it "displays growing guide details" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("Full sun")
        expect(response.body).to include("Moderate")
        expect(response.body).to include("24")
        expect(response.body).to include("A classic heirloom tomato")
      end
    end

    context "without growing guide" do
      it "shows growing guide placeholder" do
        get inventory_subcategory_variety_path(plant_type.slug, plant_category.slug, plant_subcategory.slug, plant.slug)
        expect(response.body).to include("No growing guide yet")
      end
    end
  end

  describe "GET /plants/new" do
    it "returns a successful response" do
      get new_plant_path
      expect(response).to have_http_status(:ok)
    end

    it "displays plant type options" do
      get new_plant_path
      expect(response.body).to include(plant_type.name)
    end
  end

  describe "POST /plants" do
    let(:valid_params) do
      {
        plant: {
          plant_category_id: plant_category.id,
          name: "Cherokee Purple",
          life_cycle: "annual",
          heirloom: true,
          latin_name: "Solanum lycopersicum",
          days_to_harvest_min: 75,
          days_to_harvest_max: 85,
          winter_hardy: "tender",
          planting_seasons: %w[Spring Summer],
          expected_viability_years: 5,
          notes: "Great heirloom tomato"
        }
      }
    end

    it "creates a new plant with valid params" do
      expect {
        post plants_path, params: valid_params
      }.to change(Plant, :count).by(1)
      expect(response).to redirect_to(plants_path)
    end

    it "creates a plant with a subcategory" do
      expect {
        post plants_path, params: { plant: valid_params[:plant].merge(plant_subcategory_id: plant_subcategory.id) }
      }.to change(Plant, :count).by(1)
      expect(Plant.last.plant_subcategory).to eq(plant_subcategory)
    end

    it "saves planting seasons as an array" do
      post plants_path, params: valid_params
      expect(Plant.last.planting_seasons).to eq(%w[Spring Summer])
    end

    it "does not create with missing name" do
      expect {
        post plants_path, params: { plant: valid_params[:plant].merge(name: "") }
      }.not_to change(Plant, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create with missing life_cycle" do
      expect {
        post plants_path, params: { plant: valid_params[:plant].merge(life_cycle: "") }
      }.not_to change(Plant, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create with missing plant_category_id" do
      expect {
        post plants_path, params: { plant: valid_params[:plant].merge(plant_category_id: nil) }
      }.not_to change(Plant, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /plants/:id/edit" do
    it "returns a successful response" do
      plant = create(:plant, plant_category: plant_category)
      get edit_plant_path(plant)
      expect(response).to have_http_status(:ok)
    end

    it "displays plant type options" do
      plant = create(:plant, plant_category: plant_category)
      get edit_plant_path(plant)
      expect(response.body).to include(plant_type.name)
    end
  end

  describe "PATCH /plants/:id" do
    it "updates the plant with valid params" do
      plant = create(:plant, name: "Old Name", plant_category: plant_category)
      patch plant_path(plant), params: { plant: { name: "New Name" } }
      expect(plant.reload.name).to eq("New Name")
      expect(response).to redirect_to(plants_path)
    end

    it "updates subcategory" do
      plant = create(:plant, plant_category: plant_category, plant_subcategory: nil)
      patch plant_path(plant), params: { plant: { plant_subcategory_id: plant_subcategory.id } }
      expect(plant.reload.plant_subcategory).to eq(plant_subcategory)
    end

    it "does not update with invalid params" do
      plant = create(:plant, name: "Old Name", plant_category: plant_category)
      patch plant_path(plant), params: { plant: { name: "" } }
      expect(plant.reload.name).to eq("Old Name")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /plants/:id" do
    it "deletes a plant with no purchases" do
      plant = create(:plant, plant_category: plant_category)
      expect {
        delete plant_path(plant)
      }.to change(Plant, :count).by(-1)
      expect(response).to redirect_to(plants_path)
    end

    it "does not delete a plant with purchases" do
      plant = create(:plant, plant_category: plant_category)
      create(:seed_purchase, plant: plant)
      expect {
        delete plant_path(plant)
      }.not_to change(Plant, :count)
      expect(response).to redirect_to(plants_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /plants/categories_for_type" do
    it "returns categories for a given plant type as JSON" do
      get categories_for_type_plants_path, params: { plant_type_id: plant_type.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq(plant_category.name)
    end

    it "returns empty array for type with no categories" do
      empty_type = create(:plant_type)
      get categories_for_type_plants_path, params: { plant_type_id: empty_type.id }
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end
  end

  describe "GET /plants/subcategories_for_category" do
    it "returns subcategories for a given category as JSON" do
      get subcategories_for_category_plants_path, params: { plant_category_id: plant_category.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq(plant_subcategory.name)
    end

    it "returns empty array for category with no subcategories" do
      empty_category = create(:plant_category)
      get subcategories_for_category_plants_path, params: { plant_category_id: empty_category.id }
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end
  end

  describe "POST /plants/:id/research_growing_guide" do
    let!(:plant) { create(:plant, name: "Cherokee Purple", plant_category: plant_category) }

    it "enqueues a GrowingGuideResearchJob" do
      expect {
        post research_growing_guide_plant_path(plant)
      }.to have_enqueued_job(GrowingGuideResearchJob).with(plant_category.id, "PlantCategory")
    end

    it "redirects to the plant show page" do
      post research_growing_guide_plant_path(plant)
      expect(response).to redirect_to(plant_path(plant))
    end

    it "sets a flash notice" do
      post research_growing_guide_plant_path(plant)
      expect(flash[:notice]).to include("Growing guide research started")
    end

    it "preserves back_to param in redirect" do
      post research_growing_guide_plant_path(plant), params: { back_to: "/inventory/vegetables" }
      expect(response).to redirect_to(plant_path(plant, back_to: "/inventory/vegetables"))
    end
  end

  describe "variety page with growing guide partial" do
    let!(:plant) { create(:plant, name: "Test Plant", plant_category: plant_category) }

    it "displays Research Growing Guide button when no guide exists" do
      get inventory_variety_path(plant_type.slug, plant_category.slug, plant.slug)
      expect(response.body).to include("Research Growing Guide")
    end

    it "displays Re-Research button when guide exists" do
      create(:growing_guide, plant_category: plant_category, overview: "Test", ai_generated: true, ai_generated_at: Time.current)
      get inventory_variety_path(plant_type.slug, plant_category.slug, plant.slug)
      expect(response.body).to include("Re-Research")
    end

    it "subscribes to Turbo Stream for growing guide updates" do
      get inventory_variety_path(plant_type.slug, plant_category.slug, plant.slug)
      expect(response.body).to include("turbo-cable-stream-source")
    end
  end

  describe "variety page with AI latin name indicator" do
    let!(:plant) { create(:plant, name: "Test Plant", plant_category: plant_category, latin_name: "Solanum lycopersicum") }

    it "displays the AI badge when latin_name is AI-populated" do
      plant.update!(latin_name_ai_populated: true)
      get inventory_variety_path(plant_type.slug, plant_category.slug, plant.slug)
      expect(response.body).to include("AI")
      expect(response.body).to include("AI-suggested")
    end

    it "does not display the AI badge when latin_name is not AI-populated" do
      plant.update!(latin_name_ai_populated: false)
      get inventory_variety_path(plant_type.slug, plant_category.slug, plant.slug)
      expect(response.body).to include("Solanum lycopersicum")
      expect(response.body).not_to include("AI-suggested")
    end

    it "subscribes to Turbo Stream for latin name updates" do
      get inventory_variety_path(plant_type.slug, plant_category.slug, plant.slug)
      expect(response.body).to include("turbo-cable-stream-source")
    end
  end
end
