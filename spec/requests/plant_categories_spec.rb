require "rails_helper"

RSpec.describe "PlantCategories", type: :request do
  let(:plant_type) { create(:plant_type) }

  describe "GET /plant_types/:plant_type_id/plant_categories" do
    it "returns a successful response" do
      get plant_type_plant_categories_path(plant_type)
      expect(response).to have_http_status(:ok)
    end

    it "displays categories for the plant type" do
      create(:plant_category, plant_type: plant_type, name: "Bean")
      get plant_type_plant_categories_path(plant_type)
      expect(response.body).to include("Bean")
    end

    it "shows AI badge for AI-populated viability data" do
      create(:plant_category, plant_type: plant_type, name: "Bean", expected_viability_years: 4, expected_viability_years_ai_populated: true)
      get plant_type_plant_categories_path(plant_type)
      expect(response.body).to include("AI")
    end

    it "shows Research button for categories without viability data" do
      create(:plant_category, plant_type: plant_type, name: "New Category", expected_viability_years: nil)
      get plant_type_plant_categories_path(plant_type)
      expect(response.body).to include("Research")
    end

    it "does not show Research button for categories with viability data" do
      create(:plant_category, plant_type: plant_type, name: "Bean", expected_viability_years: 4)
      get plant_type_plant_categories_path(plant_type)
      expect(response.body).not_to include("research_viability")
    end
  end

  describe "GET /plant_types/:plant_type_id/plant_categories/new" do
    it "returns a successful response" do
      get new_plant_type_plant_category_path(plant_type)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /plant_types/:plant_type_id/plant_categories" do
    it "creates a new category with valid params" do
      expect {
        post plant_type_plant_categories_path(plant_type), params: {
          plant_category: { name: "Bean", latin_genus: "Phaseolus", expected_viability_years: 4, position: 1 }
        }
      }.to change(PlantCategory, :count).by(1)
      expect(response).to redirect_to(plant_type_plant_categories_path(plant_type))
    end

    it "does not create with invalid params" do
      expect {
        post plant_type_plant_categories_path(plant_type), params: {
          plant_category: { name: "" }
        }
      }.not_to change(PlantCategory, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /plant_types/:plant_type_id/plant_categories/:id/edit" do
    it "returns a successful response" do
      category = create(:plant_category, plant_type: plant_type)
      get edit_plant_type_plant_category_path(plant_type, category)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /plant_types/:plant_type_id/plant_categories/:id" do
    it "updates the category with valid params" do
      category = create(:plant_category, plant_type: plant_type, name: "Old Name")
      patch plant_type_plant_category_path(plant_type, category), params: {
        plant_category: { name: "New Name" }
      }
      expect(category.reload.name).to eq("New Name")
      expect(response).to redirect_to(plant_type_plant_categories_path(plant_type))
    end

    it "does not update with invalid params" do
      category = create(:plant_category, plant_type: plant_type, name: "Old Name")
      patch plant_type_plant_category_path(plant_type, category), params: {
        plant_category: { name: "" }
      }
      expect(category.reload.name).to eq("Old Name")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /plant_types/:plant_type_id/plant_categories/:id/research_viability" do
    let(:category) { create(:plant_category, plant_type: plant_type, expected_viability_years: nil) }

    it "enqueues a ViabilityDataEnrichmentJob" do
      expect {
        post research_viability_plant_type_plant_category_path(plant_type, category)
      }.to have_enqueued_job(ViabilityDataEnrichmentJob).with(category.id)
    end

    it "redirects to the categories index" do
      post research_viability_plant_type_plant_category_path(plant_type, category)
      expect(response).to redirect_to(plant_type_plant_categories_path(plant_type))
    end

    it "sets a notice flash message" do
      post research_viability_plant_type_plant_category_path(plant_type, category)
      expect(flash[:notice]).to include("Viability research started")
    end
  end

  describe "DELETE /plant_types/:plant_type_id/plant_categories/:id" do
    it "deletes a category with no plants or subcategories" do
      category = create(:plant_category, plant_type: plant_type)
      expect {
        delete plant_type_plant_category_path(plant_type, category)
      }.to change(PlantCategory, :count).by(-1)
      expect(response).to redirect_to(plant_type_plant_categories_path(plant_type))
    end

    it "does not delete a category with plants" do
      category = create(:plant_category, plant_type: plant_type)
      create(:plant, plant_category: category)
      expect {
        delete plant_type_plant_category_path(plant_type, category)
      }.not_to change(PlantCategory, :count)
      expect(response).to redirect_to(plant_type_plant_categories_path(plant_type))
      expect(flash[:alert]).to be_present
    end

    it "does not delete a category with subcategories" do
      category = create(:plant_category, plant_type: plant_type)
      create(:plant_subcategory, plant_category: category)
      expect {
        delete plant_type_plant_category_path(plant_type, category)
      }.not_to change(PlantCategory, :count)
      expect(response).to redirect_to(plant_type_plant_categories_path(plant_type))
      expect(flash[:alert]).to be_present
    end
  end
end
