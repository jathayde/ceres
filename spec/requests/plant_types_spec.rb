require "rails_helper"

RSpec.describe "PlantTypes", type: :request do
  describe "GET /plant_types" do
    it "returns a successful response" do
      get plant_types_path
      expect(response).to have_http_status(:ok)
    end

    it "displays plant types" do
      create(:plant_type, name: "Vegetable")
      get plant_types_path
      expect(response.body).to include("Vegetable")
    end
  end

  describe "GET /plant_types/new" do
    it "returns a successful response" do
      get new_plant_type_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /plant_types" do
    it "creates a new plant type with valid params" do
      expect {
        post plant_types_path, params: { plant_type: { name: "Fruit", position: 1 } }
      }.to change(PlantType, :count).by(1)
      expect(response).to redirect_to(plant_types_path)
    end

    it "does not create with invalid params" do
      expect {
        post plant_types_path, params: { plant_type: { name: "" } }
      }.not_to change(PlantType, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /plant_types/:id/edit" do
    it "returns a successful response" do
      plant_type = create(:plant_type)
      get edit_plant_type_path(plant_type)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /plant_types/:id" do
    it "updates the plant type with valid params" do
      plant_type = create(:plant_type, name: "Old Name")
      patch plant_type_path(plant_type), params: { plant_type: { name: "New Name" } }
      expect(plant_type.reload.name).to eq("New Name")
      expect(response).to redirect_to(plant_types_path)
    end

    it "does not update with invalid params" do
      plant_type = create(:plant_type, name: "Old Name")
      patch plant_type_path(plant_type), params: { plant_type: { name: "" } }
      expect(plant_type.reload.name).to eq("Old Name")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /plant_types/:id" do
    it "deletes a plant type with no categories" do
      plant_type = create(:plant_type)
      expect {
        delete plant_type_path(plant_type)
      }.to change(PlantType, :count).by(-1)
      expect(response).to redirect_to(plant_types_path)
    end

    it "does not delete a plant type with categories" do
      plant_type = create(:plant_type)
      create(:plant_category, plant_type: plant_type)
      expect {
        delete plant_type_path(plant_type)
      }.not_to change(PlantType, :count)
      expect(response).to redirect_to(plant_types_path)
      expect(flash[:alert]).to be_present
    end
  end
end
