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
end
