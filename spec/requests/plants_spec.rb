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
      get plants_categories_for_type_path, params: { plant_type_id: plant_type.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq(plant_category.name)
    end

    it "returns empty array for type with no categories" do
      empty_type = create(:plant_type)
      get plants_categories_for_type_path, params: { plant_type_id: empty_type.id }
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end
  end

  describe "GET /plants/subcategories_for_category" do
    it "returns subcategories for a given category as JSON" do
      get plants_subcategories_for_category_path, params: { plant_category_id: plant_category.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to eq(plant_subcategory.name)
    end

    it "returns empty array for category with no subcategories" do
      empty_category = create(:plant_category)
      get plants_subcategories_for_category_path, params: { plant_category_id: empty_category.id }
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end
  end
end
