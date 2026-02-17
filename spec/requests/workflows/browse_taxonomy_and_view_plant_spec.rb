require "rails_helper"

RSpec.describe "Browse taxonomy hierarchy and view plant detail", type: :request do
  let!(:vegetable_type) { create(:plant_type, name: "Vegetable", position: 1) }
  let!(:herb_type) { create(:plant_type, name: "Herb", position: 2) }

  let!(:pepper_category) { create(:plant_category, plant_type: vegetable_type, name: "Pepper", expected_viability_years: 3, position: 1) }
  let!(:tomato_category) { create(:plant_category, plant_type: vegetable_type, name: "Tomato", expected_viability_years: 5, position: 2) }
  let!(:basil_category) { create(:plant_category, plant_type: herb_type, name: "Basil", expected_viability_years: 5, position: 1) }

  let!(:hot_pepper_sub) { create(:plant_subcategory, plant_category: pepper_category, name: "Hot Pepper", position: 1) }
  let!(:sweet_pepper_sub) { create(:plant_subcategory, plant_category: pepper_category, name: "Sweet Pepper", position: 2) }

  let!(:habanero) do
    create(:plant, name: "Habanero", plant_category: pepper_category, plant_subcategory: hot_pepper_sub,
           life_cycle: :annual, heirloom: true, latin_name: "Capsicum chinense",
           days_to_harvest_min: 90, days_to_harvest_max: 120, notes: "Very hot pepper")
  end
  let!(:bell_pepper) do
    create(:plant, name: "Bell Pepper", plant_category: pepper_category, plant_subcategory: sweet_pepper_sub,
           life_cycle: :annual)
  end
  let!(:cherokee_purple) do
    create(:plant, name: "Cherokee Purple", plant_category: tomato_category, life_cycle: :annual, heirloom: true)
  end
  let!(:genovese_basil) do
    create(:plant, name: "Genovese Basil", plant_category: basil_category, life_cycle: :annual)
  end

  let!(:seed_source) { create(:seed_source, name: "Baker Creek") }
  let!(:habanero_purchase) do
    create(:seed_purchase, plant: habanero, seed_source: seed_source, year_purchased: Date.current.year)
  end
  let!(:old_habanero_purchase) do
    create(:seed_purchase, plant: habanero, seed_source: seed_source, year_purchased: Date.current.year - 10, used_up: true, used_up_at: Date.current - 30)
  end

  describe "inventory home page" do
    it "shows all plants with taxonomy sidebar" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Inventory")
      expect(response.body).to include("Habanero")
      expect(response.body).to include("Bell Pepper")
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Genovese Basil")
      expect(response.body).to include("Vegetable")
      expect(response.body).to include("Herb")
    end
  end

  describe "browsing by plant type" do
    it "shows only plants within the selected type" do
      get inventory_browse_path(plant_type_id: vegetable_type.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Habanero")
      expect(response.body).to include("Bell Pepper")
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).not_to include("Genovese Basil")
    end
  end

  describe "browsing by category" do
    it "shows only plants within the selected category" do
      get inventory_browse_path(plant_type_id: vegetable_type.id, plant_category_id: pepper_category.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Habanero")
      expect(response.body).to include("Bell Pepper")
      expect(response.body).not_to include("Cherokee Purple")
      expect(response.body).not_to include("Genovese Basil")
    end
  end

  describe "browsing by subcategory" do
    it "shows only plants within the selected subcategory" do
      get inventory_browse_path(
        plant_type_id: vegetable_type.id,
        plant_category_id: pepper_category.id,
        plant_subcategory_id: hot_pepper_sub.id
      )

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Habanero")
      expect(response.body).not_to include("Bell Pepper")
      expect(response.body).not_to include("Cherokee Purple")
    end
  end

  describe "breadcrumb navigation on browse" do
    it "shows breadcrumb with type and category" do
      get inventory_browse_path(plant_type_id: vegetable_type.id, plant_category_id: pepper_category.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Vegetable")
      expect(response.body).to include("Pepper")
    end
  end

  describe "plant detail page" do
    it "shows plant metadata and purchase history" do
      get plant_path(habanero)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Habanero")
      expect(response.body).to include("Capsicum chinense")
      expect(response.body).to include("Heirloom")
      expect(response.body).to include("Annual")
      expect(response.body).to include("Very hot pepper")
      expect(response.body).to include("Plant Details")
      expect(response.body).to include("Seed Purchases")
      expect(response.body).to include("Baker Creek")
      expect(response.body).to include(Date.current.year.to_s)
    end

    it "shows viability badge on purchase" do
      get plant_path(habanero)

      expect(response.body).to include("Viable")
    end

    it "shows taxonomy breadcrumb context" do
      get plant_path(habanero)

      expect(response.body).to include("Vegetable")
      expect(response.body).to include("Pepper")
      expect(response.body).to include("Hot Pepper")
    end

    it "has Add Purchase and Edit Plant action links" do
      get plant_path(habanero)

      expect(response.body).to include("Add Purchase")
      expect(response.body).to include("Edit Plant")
    end

    it "shows both active and used-up purchases" do
      get plant_path(habanero)

      expect(response.body).to include(Date.current.year.to_s)
      expect(response.body).to include((Date.current.year - 10).to_s)
      expect(response.body).to include("Mark Used Up")
      expect(response.body).to include("Mark Active")
    end

    it "shows days to harvest range" do
      get plant_path(habanero)

      expect(response.body).to include("90")
      expect(response.body).to include("120")
    end

    it "shows plant without purchases" do
      get plant_path(bell_pepper)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bell Pepper")
      expect(response.body).to include("No seed purchases yet")
    end
  end
end
