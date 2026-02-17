require "rails_helper"

RSpec.describe "SeedPurchases", type: :request do
  let!(:plant_type) { create(:plant_type) }
  let!(:plant_category) { create(:plant_category, plant_type: plant_type, expected_viability_years: 5) }
  let!(:plant) { create(:plant, plant_category: plant_category) }
  let!(:seed_source) { create(:seed_source) }

  describe "GET /seed_purchases" do
    it "returns a successful response" do
      get seed_purchases_path
      expect(response).to have_http_status(:ok)
    end

    it "displays seed purchases" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: 2024)
      get seed_purchases_path
      expect(response.body).to include(plant.name)
      expect(response.body).to include(seed_source.name)
      expect(response.body).to include("2024")
    end

    it "displays viability badge" do
      create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year)
      get seed_purchases_path
      expect(response.body).to include("Viable")
    end

    it "displays cost when present" do
      create(:seed_purchase, plant: plant, seed_source: seed_source, cost_cents: 350)
      get seed_purchases_path
      expect(response.body).to include("$3.50")
    end
  end

  describe "GET /seed_purchases/new" do
    it "returns a successful response" do
      get new_seed_purchase_path
      expect(response).to have_http_status(:ok)
    end

    it "displays plant options" do
      get new_seed_purchase_path
      expect(response.body).to include(plant.name)
    end

    it "displays seed source options" do
      get new_seed_purchase_path
      expect(response.body).to include(seed_source.name)
    end

    it "pre-selects plant when plant_id param is provided" do
      get new_seed_purchase_path, params: { plant_id: plant.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /seed_purchases" do
    let(:valid_params) do
      {
        seed_purchase: {
          plant_id: plant.id,
          seed_source_id: seed_source.id,
          year_purchased: 2024,
          lot_number: "LOT-001",
          germination_rate: 0.85,
          seed_count: 50,
          packet_count: 2,
          cost_cents: 499,
          reorder_url: "https://example.com/seeds",
          notes: "Great variety"
        }
      }
    end

    it "creates a new seed purchase with valid params" do
      expect {
        post seed_purchases_path, params: valid_params
      }.to change(SeedPurchase, :count).by(1)
      expect(response).to redirect_to(seed_purchases_path)
    end

    it "saves all attributes correctly" do
      post seed_purchases_path, params: valid_params
      purchase = SeedPurchase.last
      expect(purchase.plant).to eq(plant)
      expect(purchase.seed_source).to eq(seed_source)
      expect(purchase.year_purchased).to eq(2024)
      expect(purchase.lot_number).to eq("LOT-001")
      expect(purchase.germination_rate).to eq(0.85)
      expect(purchase.seed_count).to eq(50)
      expect(purchase.packet_count).to eq(2)
      expect(purchase.cost_cents).to eq(499)
      expect(purchase.reorder_url).to eq("https://example.com/seeds")
      expect(purchase.notes).to eq("Great variety")
    end

    it "does not create with missing year_purchased" do
      expect {
        post seed_purchases_path, params: { seed_purchase: valid_params[:seed_purchase].merge(year_purchased: nil) }
      }.not_to change(SeedPurchase, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create with missing plant_id" do
      expect {
        post seed_purchases_path, params: { seed_purchase: valid_params[:seed_purchase].merge(plant_id: nil) }
      }.not_to change(SeedPurchase, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create with missing seed_source_id" do
      expect {
        post seed_purchases_path, params: { seed_purchase: valid_params[:seed_purchase].merge(seed_source_id: nil) }
      }.not_to change(SeedPurchase, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create with germination_rate > 1" do
      expect {
        post seed_purchases_path, params: { seed_purchase: valid_params[:seed_purchase].merge(germination_rate: 1.5) }
      }.not_to change(SeedPurchase, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /seed_purchases/:id/edit" do
    it "returns a successful response" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source)
      get edit_seed_purchase_path(purchase)
      expect(response).to have_http_status(:ok)
    end

    it "displays plant options" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source)
      get edit_seed_purchase_path(purchase)
      expect(response.body).to include(plant.name)
    end
  end

  describe "PATCH /seed_purchases/:id" do
    it "updates the seed purchase with valid params" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: 2023)
      patch seed_purchase_path(purchase), params: { seed_purchase: { year_purchased: 2024 } }
      expect(purchase.reload.year_purchased).to eq(2024)
      expect(response).to redirect_to(seed_purchases_path)
    end

    it "updates notes" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source, notes: "Old notes")
      patch seed_purchase_path(purchase), params: { seed_purchase: { notes: "New notes" } }
      expect(purchase.reload.notes).to eq("New notes")
    end

    it "does not update with invalid params" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: 2023)
      patch seed_purchase_path(purchase), params: { seed_purchase: { year_purchased: nil } }
      expect(purchase.reload.year_purchased).to eq(2023)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /seed_purchases/:id" do
    it "deletes a seed purchase" do
      purchase = create(:seed_purchase, plant: plant, seed_source: seed_source)
      expect {
        delete seed_purchase_path(purchase)
      }.to change(SeedPurchase, :count).by(-1)
      expect(response).to redirect_to(seed_purchases_path)
    end
  end

  describe "GET /seed_purchases/plants_search" do
    it "returns plants matching the query" do
      create(:plant, name: "Cherokee Purple", plant_category: plant_category)
      get seed_purchases_plants_search_path, params: { q: "Cherokee" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["name"]).to include("Cherokee Purple")
    end

    it "returns empty array for non-matching query" do
      get seed_purchases_plants_search_path, params: { q: "Nonexistent" }
      json = JSON.parse(response.body)
      expect(json).to be_empty
    end
  end
end
