require "rails_helper"

RSpec.describe "Inventory", type: :request do
  let!(:plant_type) { create(:plant_type, name: "Vegetable") }
  let!(:plant_category) { create(:plant_category, name: "Tomato", plant_type: plant_type, expected_viability_years: 5) }
  let!(:plant_subcategory) { create(:plant_subcategory, name: "Cherry", plant_category: plant_category) }
  let!(:plant) { create(:plant, name: "Sun Gold", plant_category: plant_category, plant_subcategory: plant_subcategory, heirloom: false) }
  let!(:heirloom_plant) { create(:plant, name: "Brandywine", plant_category: plant_category, heirloom: true) }

  describe "GET / (inventory index)" do
    it "returns a successful response" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the taxonomy sidebar" do
      get root_path
      expect(response.body).to include("Browse by Type")
      expect(response.body).to include(plant_type.name)
    end

    it "displays all plants" do
      get root_path
      expect(response.body).to include("Sun Gold")
      expect(response.body).to include("Brandywine")
    end

    it "displays heirloom badge" do
      get root_path
      expect(response.body).to include("Heirloom")
    end

    it "displays plant category in sidebar" do
      get root_path
      expect(response.body).to include(plant_category.name)
    end

    it "displays plant subcategory in sidebar" do
      get root_path
      expect(response.body).to include(plant_subcategory.name)
    end
  end

  describe "GET /inventory/browse" do
    context "browsing by plant type" do
      it "returns a successful response" do
        get inventory_browse_path(plant_type_id: plant_type.id)
        expect(response).to have_http_status(:ok)
      end

      it "shows plants within the type" do
        get inventory_browse_path(plant_type_id: plant_type.id)
        expect(response.body).to include("Sun Gold")
        expect(response.body).to include("Brandywine")
      end

      it "does not show plants from other types" do
        other_type = create(:plant_type, name: "Herb")
        other_category = create(:plant_category, name: "Basil", plant_type: other_type)
        create(:plant, name: "Genovese Basil", plant_category: other_category)

        get inventory_browse_path(plant_type_id: plant_type.id)
        expect(response.body).not_to include("Genovese Basil")
      end

      it "shows breadcrumb with type name" do
        get inventory_browse_path(plant_type_id: plant_type.id)
        expect(response.body).to include("All Plants")
        expect(response.body).to include(plant_type.name)
      end
    end

    context "browsing by plant category" do
      it "returns a successful response" do
        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id)
        expect(response).to have_http_status(:ok)
      end

      it "shows plants within the category" do
        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id)
        expect(response.body).to include("Sun Gold")
        expect(response.body).to include("Brandywine")
      end

      it "shows breadcrumb with category name" do
        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id)
        expect(response.body).to include(plant_category.name)
      end

      it "does not show plants from other categories" do
        other_category = create(:plant_category, name: "Pepper", plant_type: plant_type)
        create(:plant, name: "Jalapeno", plant_category: other_category)

        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id)
        expect(response.body).not_to include("Jalapeno")
      end
    end

    context "browsing by plant subcategory" do
      it "returns a successful response" do
        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id, plant_subcategory_id: plant_subcategory.id)
        expect(response).to have_http_status(:ok)
      end

      it "shows only plants in the subcategory" do
        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id, plant_subcategory_id: plant_subcategory.id)
        expect(response.body).to include("Sun Gold")
        expect(response.body).not_to include("Brandywine")
      end

      it "shows breadcrumb with subcategory name" do
        get inventory_browse_path(plant_type_id: plant_type.id, plant_category_id: plant_category.id, plant_subcategory_id: plant_subcategory.id)
        expect(response.body).to include(plant_subcategory.name)
      end
    end

    context "plant list content" do
      let!(:seed_source) { create(:seed_source) }
      let!(:purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year) }

      it "displays latin name when present" do
        plant.update!(latin_name: "Solanum lycopersicum")
        get root_path
        expect(response.body).to include("Solanum lycopersicum")
      end

      it "displays viability status for plants with purchases" do
        get root_path
        expect(response.body).to include("Viable")
      end

      it "displays active purchase count" do
        get root_path
        expect(response.body).to include("1")
      end

      it "shows 'No purchases' for plants without seed purchases" do
        get root_path
        expect(response.body).to include("No purchases")
      end
    end
  end

  describe "filter functionality" do
    let!(:seed_source) { create(:seed_source, name: "Baker Creek") }
    let!(:other_source) { create(:seed_source, name: "Territorial") }
    let!(:viable_purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year) }
    let!(:expired_purchase) { create(:seed_purchase, plant: heirloom_plant, seed_source: other_source, year_purchased: Date.current.year - 10) }

    it "renders filter buttons on index" do
      get root_path
      expect(response.body).to include("Viable Only")
      expect(response.body).to include("Needs Testing")
      expect(response.body).to include("Expired")
      expect(response.body).to include("Heirloom")
    end

    it "renders filter buttons on browse" do
      get inventory_browse_path(plant_type_id: plant_type.id)
      expect(response.body).to include("Viable Only")
    end

    it "renders seed source dropdown" do
      get root_path
      expect(response.body).to include("Baker Creek")
      expect(response.body).to include("Territorial")
    end

    context "filtering by viability status" do
      it "filters to viable plants only" do
        get root_path, params: { viability: "viable" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
        expect(response.body).not_to include("Brandywine")
      end

      it "filters to expired plants only" do
        get root_path, params: { viability: "expired" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Brandywine")
        expect(response.body).not_to include("Sun Gold")
      end
    end

    context "filtering by heirloom" do
      it "shows only heirloom plants" do
        get root_path, params: { heirloom: "1" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Brandywine")
        expect(response.body).not_to include("Sun Gold")
      end
    end

    context "filtering by seed source" do
      it "shows only plants from the selected seed source" do
        get root_path, params: { seed_source_id: seed_source.id }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
        expect(response.body).not_to include("Brandywine")
      end
    end

    context "combining filters" do
      it "combines viability and taxonomy navigation" do
        get inventory_browse_path, params: { plant_type_id: plant_type.id, viability: "viable" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
        expect(response.body).not_to include("Brandywine")
      end

      it "combines search and viability filter" do
        get root_path, params: { q: "Sun", viability: "viable" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
      end

      it "combines heirloom and viability filters" do
        get root_path, params: { heirloom: "1", viability: "expired" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Brandywine")
        expect(response.body).not_to include("Sun Gold")
      end
    end

    context "clear filters" do
      it "shows clear filters button when filters are active" do
        get root_path, params: { viability: "viable" }
        expect(response.body).to include("Clear filters")
      end

      it "does not show clear filters button when no filters active" do
        get root_path
        expect(response.body).not_to include("Clear filters")
      end
    end

    context "active filter indicators" do
      it "highlights active viability filter" do
        get root_path, params: { viability: "viable" }
        expect(response.body).to include("bg-green-600")
      end

      it "highlights active heirloom filter" do
        get root_path, params: { heirloom: "1" }
        expect(response.body).to include("bg-purple-600")
      end
    end
  end

  describe "bulk select UI" do
    let!(:seed_source) { create(:seed_source, name: "Baker Creek") }
    let!(:purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year) }

    it "shows bulk select checkboxes on index" do
      get root_path
      expect(response.body).to include("bulk-select")
      expect(response.body).to include("inventory-bulk-form")
    end

    it "shows bulk select checkboxes on browse" do
      get inventory_browse_path(plant_type_id: plant_type.id)
      expect(response.body).to include("bulk-select")
      expect(response.body).to include("inventory-bulk-form")
    end

    it "shows checkboxes for plants with active purchases" do
      get root_path
      expect(response.body).to include("name=\"plant_ids[]\" value=\"#{plant.id}\"")
    end

    it "does not show checkboxes for plants without active purchases" do
      get root_path
      expect(response.body).not_to include("name=\"plant_ids[]\" value=\"#{heirloom_plant.id}\"")
    end

    it "shows Mark Selected as Used Up button" do
      get root_path
      expect(response.body).to include("Mark Selected as Used Up")
    end
  end

  describe "PATCH /inventory/bulk_mark_used_up" do
    let!(:seed_source) { create(:seed_source, name: "Baker Creek") }
    let!(:purchase1) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year, used_up: false) }
    let!(:purchase2) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year - 1, used_up: false) }
    let!(:heirloom_purchase) { create(:seed_purchase, plant: heirloom_plant, seed_source: seed_source, year_purchased: Date.current.year, used_up: false) }
    let!(:already_used) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year - 5, used_up: true, used_up_at: Date.current) }

    it "marks all active purchases for selected plants as used up" do
      patch bulk_mark_used_up_inventory_path, params: { plant_ids: [ plant.id ] }
      purchase1.reload
      purchase2.reload
      expect(purchase1.used_up?).to be true
      expect(purchase1.used_up_at).to eq(Date.current)
      expect(purchase2.used_up?).to be true
      expect(purchase2.used_up_at).to eq(Date.current)
    end

    it "does not affect purchases from unselected plants" do
      patch bulk_mark_used_up_inventory_path, params: { plant_ids: [ plant.id ] }
      heirloom_purchase.reload
      expect(heirloom_purchase.used_up?).to be false
    end

    it "does not re-mark already used-up purchases" do
      original_date = already_used.used_up_at
      patch bulk_mark_used_up_inventory_path, params: { plant_ids: [ plant.id ] }
      already_used.reload
      expect(already_used.used_up_at).to eq(original_date)
    end

    it "marks purchases from multiple selected plants" do
      patch bulk_mark_used_up_inventory_path, params: { plant_ids: [ plant.id, heirloom_plant.id ] }
      purchase1.reload
      heirloom_purchase.reload
      expect(purchase1.used_up?).to be true
      expect(heirloom_purchase.used_up?).to be true
    end

    it "redirects with count notice" do
      patch bulk_mark_used_up_inventory_path, params: { plant_ids: [ plant.id ] }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("2 purchases marked as used up")
    end

    it "shows alert when no plants selected" do
      patch bulk_mark_used_up_inventory_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("No plants were selected")
    end
  end

  describe "search functionality" do
    it "displays a search bar on the index page" do
      get root_path
      expect(response.body).to include("Search plants")
    end

    it "displays a search bar on the browse page" do
      get inventory_browse_path(plant_type_id: plant_type.id)
      expect(response.body).to include("Search plants")
    end

    context "searching by plant name" do
      it "returns matching plants" do
        get root_path, params: { q: "Sun Gold" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
        expect(response.body).not_to include("Brandywine")
      end

      it "shows search results heading with query" do
        get root_path, params: { q: "Sun Gold" }
        expect(response.body).to include("Search results")
        expect(response.body).to include("Sun Gold")
      end

      it "shows result count" do
        get root_path, params: { q: "Sun Gold" }
        expect(response.body).to include("1 found")
      end
    end

    context "searching by latin name" do
      before { plant.update!(latin_name: "Solanum lycopersicum") }

      it "returns plants matching latin name" do
        get root_path, params: { q: "Solanum" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
      end
    end

    context "searching by plant notes" do
      before { plant.update!(notes: "Excellent cherry tomato for containers") }

      it "returns plants matching notes content" do
        get root_path, params: { q: "containers" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
      end
    end

    context "searching by seed source name" do
      let!(:seed_source) { create(:seed_source, name: "Johnny's Selected Seeds") }
      let!(:purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source) }

      it "returns plants matching seed source name" do
        get root_path, params: { q: "Johnny" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
      end
    end

    context "empty search" do
      it "shows all plants when search query is empty" do
        get root_path, params: { q: "" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
        expect(response.body).to include("Brandywine")
      end

      it "shows all plants heading" do
        get root_path, params: { q: "" }
        expect(response.body).to include("All Plants")
      end
    end

    context "no results" do
      it "returns an empty result set for non-matching query" do
        get root_path, params: { q: "nonexistent" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("0 found")
      end
    end

    context "search combined with taxonomy navigation" do
      let!(:herb_type) { create(:plant_type, name: "Herb") }
      let!(:herb_category) { create(:plant_category, name: "Basil", plant_type: herb_type) }
      let!(:herb_plant) { create(:plant, name: "Sun Basil", plant_category: herb_category) }

      it "searches within a specific plant type" do
        get inventory_browse_path, params: { plant_type_id: plant_type.id, q: "Sun" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
        expect(response.body).not_to include("Sun Basil")
      end

      it "searches within a specific category" do
        get inventory_browse_path, params: { plant_category_id: plant_category.id, q: "Brandywine" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Brandywine")
      end
    end

    context "prefix matching" do
      it "matches partial words from the beginning" do
        get root_path, params: { q: "Brand" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Brandywine")
      end
    end

    context "search displays plant details" do
      let!(:seed_source) { create(:seed_source) }
      let!(:purchase) { create(:seed_purchase, plant: plant, seed_source: seed_source, year_purchased: Date.current.year) }

      it "shows category for search results" do
        get root_path, params: { q: "Sun Gold" }
        expect(response.body).to include("Tomato")
      end

      it "shows viability status for search results" do
        get root_path, params: { q: "Sun Gold" }
        expect(response.body).to include("Viable")
      end
    end
  end
end
