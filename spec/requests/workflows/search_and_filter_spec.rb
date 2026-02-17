require "rails_helper"

RSpec.describe "Search for a plant and filter by viability status", type: :request do
  let!(:vegetable_type) { create(:plant_type, name: "Vegetable", position: 1) }
  let!(:herb_type) { create(:plant_type, name: "Herb", position: 2) }

  let!(:tomato_category) { create(:plant_category, plant_type: vegetable_type, name: "Tomato", expected_viability_years: 5, position: 1) }
  let!(:pepper_category) { create(:plant_category, plant_type: vegetable_type, name: "Pepper", expected_viability_years: 3, position: 2) }
  let!(:basil_category) { create(:plant_category, plant_type: herb_type, name: "Basil", expected_viability_years: 5, position: 1) }

  let!(:cherokee_purple) do
    create(:plant, name: "Cherokee Purple", plant_category: tomato_category, life_cycle: :annual, heirloom: true)
  end
  let!(:roma) do
    create(:plant, name: "Roma", plant_category: tomato_category, life_cycle: :annual)
  end
  let!(:habanero) do
    create(:plant, name: "Habanero", plant_category: pepper_category, life_cycle: :annual, heirloom: true)
  end
  let!(:genovese_basil) do
    create(:plant, name: "Genovese Basil", plant_category: basil_category, life_cycle: :annual)
  end

  let!(:seed_source) { create(:seed_source, name: "Baker Creek") }
  let!(:other_source) { create(:seed_source, name: "Johnnys Seeds") }

  # Viable purchase (purchased this year, viability 5 years)
  let!(:viable_purchase) do
    create(:seed_purchase, plant: cherokee_purple, seed_source: seed_source, year_purchased: Date.current.year)
  end

  # Needs testing purchase (purchased 6 years ago, viability 5 years, within +2 window)
  let!(:test_purchase) do
    create(:seed_purchase, plant: roma, seed_source: seed_source, year_purchased: Date.current.year - 6)
  end

  # Expired purchase (purchased 10 years ago, viability 3 years, well past +2 window)
  let!(:expired_purchase) do
    create(:seed_purchase, plant: habanero, seed_source: other_source, year_purchased: Date.current.year - 10)
  end

  # Viable basil purchase
  let!(:basil_purchase) do
    create(:seed_purchase, plant: genovese_basil, seed_source: other_source, year_purchased: Date.current.year)
  end

  describe "full-text search" do
    it "finds plants by name" do
      get root_path(q: "Cherokee")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Search results for")
      expect(response.body).not_to include("Roma</a>")
    end

    it "finds plants by partial name match" do
      get root_path(q: "basil")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Genovese Basil")
    end

    it "shows count of results" do
      get root_path(q: "Cherokee")

      expect(response.body).to include("1 found")
    end

    it "shows all plants when search is empty" do
      get root_path(q: "")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("All Plants")
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Roma")
      expect(response.body).to include("Habanero")
      expect(response.body).to include("Genovese Basil")
    end

    it "returns empty results for non-matching search" do
      get root_path(q: "Watermelon")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("0 found")
    end
  end

  describe "viability status filters" do
    it "filters to show only viable plants" do
      get root_path(viability: "viable")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Genovese Basil")
      expect(response.body).not_to include("Habanero")
    end

    it "filters to show only needs-testing plants" do
      get root_path(viability: "test")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Roma")
      expect(response.body).not_to include("Cherokee Purple")
    end

    it "filters to show only expired plants" do
      get root_path(viability: "expired")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Habanero")
      expect(response.body).not_to include("Cherokee Purple")
      expect(response.body).not_to include("Genovese Basil")
    end
  end

  describe "heirloom filter" do
    it "filters to show only heirloom plants" do
      get root_path(heirloom: "1")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Habanero")
      expect(response.body).not_to include("Roma</a>")
      expect(response.body).not_to include("Genovese Basil")
    end
  end

  describe "seed source filter" do
    it "filters by seed source" do
      get root_path(seed_source_id: seed_source.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Roma")
      expect(response.body).not_to include("Habanero")
    end
  end

  describe "combined filters" do
    it "combines viability and heirloom filters" do
      get root_path(viability: "viable", heirloom: "1")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).not_to include("Roma</a>")
      expect(response.body).not_to include("Genovese Basil")
    end

    it "combines search with viability filter" do
      get root_path(q: "Cherokee", viability: "viable")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
    end

    it "combines filters with taxonomy browsing" do
      get inventory_browse_path(plant_type_id: vegetable_type.id, viability: "viable")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cherokee Purple")
      expect(response.body).not_to include("Genovese Basil")
    end
  end

  describe "filter state indicators" do
    it "shows active filter state for viability" do
      get root_path(viability: "viable")

      # Active viability filter should have distinct styling
      expect(response.body).to include("viability=viable")
    end

    it "shows clear filters link when filters are active" do
      get root_path(viability: "viable")

      expect(response.body).to include("Clear")
    end

    it "does not show clear filters when no filters active" do
      get root_path

      expect(response.body).not_to include("Clear all")
    end
  end
end
