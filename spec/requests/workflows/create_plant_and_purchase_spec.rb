require "rails_helper"

RSpec.describe "Create a new plant with category and add a seed purchase", type: :request do
  let!(:vegetable_type) { create(:plant_type, name: "Vegetable", position: 1) }
  let!(:tomato_category) { create(:plant_category, plant_type: vegetable_type, name: "Tomato", expected_viability_years: 5, position: 1) }
  let!(:seed_source) { create(:seed_source, name: "Baker Creek") }

  describe "creating a new plant" do
    it "renders the new plant form" do
      get new_plant_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Plant")
      expect(response.body).to include("Classification")
      expect(response.body).to include("Name")
      expect(response.body).to include("Life cycle")
    end

    it "creates a plant with required fields" do
      expect {
        post plants_path, params: {
          plant: {
            plant_category_id: tomato_category.id,
            name: "Cherokee Purple",
            life_cycle: "annual"
          }
        }
      }.to change(Plant, :count).by(1)

      expect(response).to redirect_to(plants_path)
      follow_redirect!
      expect(response.body).to include("Plant was successfully created")
      expect(response.body).to include("Cherokee Purple")
    end

    it "creates a plant with all optional fields" do
      expect {
        post plants_path, params: {
          plant: {
            plant_category_id: tomato_category.id,
            name: "Brandywine",
            latin_name: "Solanum lycopersicum",
            life_cycle: "annual",
            heirloom: true,
            days_to_harvest_min: 80,
            days_to_harvest_max: 100,
            winter_hardy: "tender",
            expected_viability_years: 6,
            notes: "Classic heirloom tomato",
            planting_seasons: [ "Spring", "Summer" ]
          }
        }
      }.to change(Plant, :count).by(1)

      plant = Plant.last
      expect(plant.name).to eq("Brandywine")
      expect(plant.latin_name).to eq("Solanum lycopersicum")
      expect(plant.heirloom).to be true
      expect(plant.days_to_harvest_min).to eq(80)
      expect(plant.days_to_harvest_max).to eq(100)
      expect(plant.winter_hardy).to eq("tender")
      expect(plant.expected_viability_years).to eq(6)
      expect(plant.notes).to eq("Classic heirloom tomato")
      expect(plant.planting_seasons).to include("Spring", "Summer")
    end

    it "rejects creation without required fields" do
      expect {
        post plants_path, params: {
          plant: {
            plant_category_id: tomato_category.id,
            name: "",
            life_cycle: "annual"
          }
        }
      }.not_to change(Plant, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "shows the created plant in the inventory" do
      post plants_path, params: {
        plant: {
          plant_category_id: tomato_category.id,
          name: "San Marzano",
          life_cycle: "annual"
        }
      }

      get root_path
      expect(response.body).to include("San Marzano")
    end
  end

  describe "adding a seed purchase to a plant" do
    let!(:plant) do
      create(:plant, name: "Cherokee Purple", plant_category: tomato_category, life_cycle: :annual)
    end

    it "renders the new purchase form" do
      get new_seed_purchase_path(plant_id: plant.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Seed Purchase")
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Baker Creek")
    end

    it "creates a seed purchase with required fields" do
      expect {
        post seed_purchases_path, params: {
          seed_purchase: {
            plant_id: plant.id,
            seed_source_id: seed_source.id,
            year_purchased: Date.current.year
          }
        }
      }.to change(SeedPurchase, :count).by(1)

      expect(response).to redirect_to(seed_purchases_path)
      follow_redirect!
      expect(response.body).to include("Seed purchase was successfully created")
    end

    it "creates a purchase with all optional fields" do
      expect {
        post seed_purchases_path, params: {
          seed_purchase: {
            plant_id: plant.id,
            seed_source_id: seed_source.id,
            year_purchased: Date.current.year,
            lot_number: "LOT-2026-A",
            germination_rate: 0.92,
            seed_count: 50,
            packet_count: 2,
            cost_cents: 350,
            notes: "Bought at garden show"
          }
        }
      }.to change(SeedPurchase, :count).by(1)

      purchase = SeedPurchase.last
      expect(purchase.lot_number).to eq("LOT-2026-A")
      expect(purchase.germination_rate).to eq(0.92)
      expect(purchase.seed_count).to eq(50)
      expect(purchase.packet_count).to eq(2)
      expect(purchase.cost_cents).to eq(350)
      expect(purchase.notes).to eq("Bought at garden show")
    end

    it "shows the purchase on the plant detail page" do
      post seed_purchases_path, params: {
        seed_purchase: {
          plant_id: plant.id,
          seed_source_id: seed_source.id,
          year_purchased: 2025,
          lot_number: "XYZ-123"
        }
      }

      get inventory_variety_path(vegetable_type.slug, tomato_category.slug, plant.slug)
      expect(response.body).to include("Baker Creek")
      expect(response.body).to include("2025")
      expect(response.body).to include("XYZ-123")
    end

    it "rejects purchase without required plant" do
      expect {
        post seed_purchases_path, params: {
          seed_purchase: {
            seed_source_id: seed_source.id,
            year_purchased: Date.current.year
          }
        }
      }.not_to change(SeedPurchase, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "end-to-end: create plant then add purchase" do
    it "creates a plant and then adds a purchase to it" do
      # Step 1: Create the plant
      post plants_path, params: {
        plant: {
          plant_category_id: tomato_category.id,
          name: "Roma",
          life_cycle: "annual"
        }
      }
      plant = Plant.find_by!(name: "Roma")
      expect(response).to redirect_to(plants_path)

      # Step 2: View the plant detail via inventory URL
      get inventory_variety_path(vegetable_type.slug, tomato_category.slug, plant.slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Roma")
      expect(response.body).to include("No seed purchases yet")

      # Step 3: Add a purchase
      post seed_purchases_path, params: {
        seed_purchase: {
          plant_id: plant.id,
          seed_source_id: seed_source.id,
          year_purchased: Date.current.year,
          packet_count: 1
        }
      }
      expect(response).to redirect_to(seed_purchases_path)

      # Step 4: Verify purchase appears on plant detail
      get inventory_variety_path(vegetable_type.slug, tomato_category.slug, plant.slug)
      expect(response.body).to include("Baker Creek")
      expect(response.body).to include(Date.current.year.to_s)
      expect(response.body).not_to include("No seed purchases yet")

      # Step 5: Verify plant appears in inventory with purchase count
      get root_path
      expect(response.body).to include("Roma")
    end
  end
end
