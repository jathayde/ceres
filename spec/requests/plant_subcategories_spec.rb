require "rails_helper"

RSpec.describe "PlantSubcategories", type: :request do
  let(:plant_type) { create(:plant_type) }
  let(:plant_category) { create(:plant_category, plant_type: plant_type) }

  describe "GET /plant_types/:plant_type_id/plant_categories/:plant_category_id/plant_subcategories" do
    it "returns a successful response" do
      get plant_type_plant_category_plant_subcategories_path(plant_type, plant_category)
      expect(response).to have_http_status(:ok)
    end

    it "displays subcategories for the category" do
      create(:plant_subcategory, plant_category: plant_category, name: "Bush")
      get plant_type_plant_category_plant_subcategories_path(plant_type, plant_category)
      expect(response.body).to include("Bush")
    end
  end

  describe "GET /plant_types/.../plant_subcategories/new" do
    it "returns a successful response" do
      get new_plant_type_plant_category_plant_subcategory_path(plant_type, plant_category)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /plant_types/.../plant_subcategories" do
    it "creates a new subcategory with valid params" do
      expect {
        post plant_type_plant_category_plant_subcategories_path(plant_type, plant_category), params: {
          plant_subcategory: { name: "Bush", position: 1 }
        }
      }.to change(PlantSubcategory, :count).by(1)
      expect(response).to redirect_to(plant_type_plant_category_plant_subcategories_path(plant_type, plant_category))
    end

    it "does not create with invalid params" do
      expect {
        post plant_type_plant_category_plant_subcategories_path(plant_type, plant_category), params: {
          plant_subcategory: { name: "" }
        }
      }.not_to change(PlantSubcategory, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /plant_types/.../plant_subcategories/:id/edit" do
    it "returns a successful response" do
      subcategory = create(:plant_subcategory, plant_category: plant_category)
      get edit_plant_type_plant_category_plant_subcategory_path(plant_type, plant_category, subcategory)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /plant_types/.../plant_subcategories/:id" do
    it "updates the subcategory with valid params" do
      subcategory = create(:plant_subcategory, plant_category: plant_category, name: "Old Name")
      patch plant_type_plant_category_plant_subcategory_path(plant_type, plant_category, subcategory), params: {
        plant_subcategory: { name: "New Name" }
      }
      expect(subcategory.reload.name).to eq("New Name")
      expect(response).to redirect_to(plant_type_plant_category_plant_subcategories_path(plant_type, plant_category))
    end

    it "does not update with invalid params" do
      subcategory = create(:plant_subcategory, plant_category: plant_category, name: "Old Name")
      patch plant_type_plant_category_plant_subcategory_path(plant_type, plant_category, subcategory), params: {
        plant_subcategory: { name: "" }
      }
      expect(subcategory.reload.name).to eq("Old Name")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /plant_types/.../plant_subcategories/:id" do
    it "deletes a subcategory with no plants" do
      subcategory = create(:plant_subcategory, plant_category: plant_category)
      expect {
        delete plant_type_plant_category_plant_subcategory_path(plant_type, plant_category, subcategory)
      }.to change(PlantSubcategory, :count).by(-1)
      expect(response).to redirect_to(plant_type_plant_category_plant_subcategories_path(plant_type, plant_category))
    end

    it "does not delete a subcategory with plants" do
      subcategory = create(:plant_subcategory, plant_category: plant_category)
      create(:plant, plant_category: plant_category, plant_subcategory: subcategory)
      expect {
        delete plant_type_plant_category_plant_subcategory_path(plant_type, plant_category, subcategory)
      }.not_to change(PlantSubcategory, :count)
      expect(response).to redirect_to(plant_type_plant_category_plant_subcategories_path(plant_type, plant_category))
      expect(flash[:alert]).to be_present
    end
  end
end
