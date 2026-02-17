require "rails_helper"

RSpec.describe "View viability audit dashboard with correct status badges", type: :request do
  let!(:vegetable_type) { create(:plant_type, name: "Vegetable", position: 1) }
  let!(:herb_type) { create(:plant_type, name: "Herb", position: 2) }

  let!(:tomato_category) { create(:plant_category, plant_type: vegetable_type, name: "Tomato", expected_viability_years: 5, position: 1) }
  let!(:pepper_category) { create(:plant_category, plant_type: vegetable_type, name: "Pepper", expected_viability_years: 3, position: 2) }
  let!(:basil_category) { create(:plant_category, plant_type: herb_type, name: "Basil", expected_viability_years: 5, position: 1) }

  let!(:cherokee_purple) { create(:plant, name: "Cherokee Purple", plant_category: tomato_category, life_cycle: :annual) }
  let!(:roma) { create(:plant, name: "Roma", plant_category: tomato_category, life_cycle: :annual) }
  let!(:habanero) { create(:plant, name: "Habanero", plant_category: pepper_category, life_cycle: :annual) }
  let!(:genovese_basil) { create(:plant, name: "Genovese Basil", plant_category: basil_category, life_cycle: :annual) }

  let!(:baker_creek) { create(:seed_source, name: "Baker Creek") }
  let!(:johnnys) { create(:seed_source, name: "Johnnys Seeds") }

  # Viable: purchased this year, 5-year viability
  let!(:viable_purchase) do
    create(:seed_purchase, plant: cherokee_purple, seed_source: baker_creek, year_purchased: Date.current.year)
  end

  # Needs testing: purchased 6 years ago, 5-year viability (age 6, within +2 window)
  let!(:test_purchase) do
    create(:seed_purchase, plant: roma, seed_source: baker_creek, year_purchased: Date.current.year - 6)
  end

  # Expired: purchased 10 years ago, 3-year viability (age 10, well past +2 window)
  let!(:expired_purchase) do
    create(:seed_purchase, plant: habanero, seed_source: johnnys, year_purchased: Date.current.year - 10)
  end

  # Another viable purchase
  let!(:basil_purchase) do
    create(:seed_purchase, plant: genovese_basil, seed_source: johnnys, year_purchased: Date.current.year)
  end

  # Used up purchase (should not appear in audit)
  let!(:used_up_purchase) do
    create(:seed_purchase, plant: cherokee_purple, seed_source: baker_creek,
           year_purchased: Date.current.year - 8, used_up: true, used_up_at: Date.current - 30)
  end

  describe "dashboard summary" do
    it "shows the audit page with title and summary cards" do
      get viability_audit_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Viability Audit")
      expect(response.body).to include("Review seed viability status across your inventory")
    end

    it "shows correct summary counts" do
      get viability_audit_path

      # 2 viable (Cherokee Purple + Genovese Basil), 1 test (Roma), 1 expired (Habanero)
      expect(response.body).to include(">2</div>")
      expect(response.body).to include(">1</div>")
      expect(response.body).to include("Viable")
      expect(response.body).to include("Needs Testing")
      expect(response.body).to include("Expired")
    end

    it "shows all active purchases in the table" do
      get viability_audit_path

      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Roma")
      expect(response.body).to include("Habanero")
      expect(response.body).to include("Genovese Basil")
    end

    it "does not show used-up purchases" do
      get viability_audit_path

      # The used_up_purchase year should not appear as a row
      # But Cherokee Purple's active purchase year should appear
      expect(response.body).to include(Date.current.year.to_s)
      # Ensure we have 4 active purchases in the table, not 5
      expect(response.body).to include("4 active purchase")
    end
  end

  describe "viability status badges" do
    it "shows correct badge for viable purchase" do
      get viability_audit_path

      # Viable badge: green background
      expect(response.body).to include("bg-green-100 text-green-800")
      expect(response.body).to match(/Viable/)
    end

    it "shows correct badge for needs-testing purchase" do
      get viability_audit_path

      # Test badge: amber background
      expect(response.body).to include("bg-amber-100 text-amber-800")
      expect(response.body).to match(/Test/)
    end

    it "shows correct badge for expired purchase" do
      get viability_audit_path

      # Expired badge: red background
      expect(response.body).to include("bg-red-100 text-red-800")
      expect(response.body).to match(/Expired/)
    end
  end

  describe "color-coded rows" do
    it "has green background for viable purchases" do
      get viability_audit_path
      expect(response.body).to include("bg-green-50")
    end

    it "has amber background for test purchases" do
      get viability_audit_path
      expect(response.body).to include("bg-amber-50")
    end

    it "has red background for expired purchases" do
      get viability_audit_path
      expect(response.body).to include("bg-red-50")
    end
  end

  describe "sorting" do
    it "sorts by urgency by default (oldest first)" do
      get viability_audit_path

      # Urgency sort = year_purchased ASC, so oldest (10 years ago) first
      body = response.body
      habanero_pos = body.index("Habanero")
      cherokee_pos = body.index("Cherokee Purple")
      expect(habanero_pos).to be < cherokee_pos
    end

    it "sorts by plant name" do
      get viability_audit_path(sort: "name")

      body = response.body
      cherokee_pos = body.index("Cherokee Purple")
      roma_pos = body.index("Roma</a>")
      expect(cherokee_pos).to be < roma_pos
    end

    it "shows sort options" do
      get viability_audit_path

      expect(response.body).to include("Sort by:")
      expect(response.body).to include("Urgency")
      expect(response.body).to include("Plant Name")
      expect(response.body).to include("Category")
      expect(response.body).to include("Source")
      expect(response.body).to include("Year")
    end
  end

  describe "filtering" do
    it "filters by viability status - viable only" do
      get viability_audit_path(viability: "viable")

      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Genovese Basil")
      expect(response.body).not_to include("Habanero")
    end

    it "filters by viability status - expired only" do
      get viability_audit_path(viability: "expired")

      expect(response.body).to include("Habanero")
      expect(response.body).not_to include("Cherokee Purple")
      expect(response.body).not_to include("Roma</a>")
    end

    it "filters by plant type" do
      get viability_audit_path(plant_type_id: vegetable_type.id)

      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Roma")
      expect(response.body).to include("Habanero")
      expect(response.body).not_to include("Genovese Basil")
    end

    it "filters by plant category" do
      get viability_audit_path(plant_category_id: tomato_category.id)

      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Roma")
      expect(response.body).not_to include("Habanero")
    end

    it "filters by seed source" do
      get viability_audit_path(seed_source_id: baker_creek.id)

      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Roma")
      expect(response.body).not_to include("Habanero")
      expect(response.body).not_to include("Genovese Basil")
    end

    it "filters by year range" do
      get viability_audit_path(year_from: Date.current.year - 1, year_to: Date.current.year)

      expect(response.body).to include("Cherokee Purple")
      expect(response.body).to include("Genovese Basil")
      expect(response.body).not_to include("Habanero")
    end

    it "shows clear filters link when filters active" do
      get viability_audit_path(viability: "viable")
      expect(response.body).to include("Clear filters")
    end

    it "does not show clear filters when no filters active" do
      get viability_audit_path
      expect(response.body).not_to include("Clear filters")
    end
  end

  describe "audit actions" do
    it "shows Mark Used Up button for each purchase" do
      get viability_audit_path
      expect(response.body).to include("Mark Used Up")
    end

    it "shows reviewed checkbox for each purchase" do
      get viability_audit_path
      expect(response.body).to include("Mark as reviewed")
    end

    it "shows purchase table columns" do
      get viability_audit_path

      expect(response.body).to include("Plant")
      expect(response.body).to include("Category")
      expect(response.body).to include("Source")
      expect(response.body).to include("Year")
      expect(response.body).to include("Status")
    end

    it "links plant names to plant detail page" do
      get viability_audit_path

      expect(response.body).to include(plant_path(cherokee_purple))
      expect(response.body).to include(plant_path(habanero))
    end
  end

  describe "empty state" do
    it "shows empty message when no active purchases" do
      SeedPurchase.update_all(used_up: true, used_up_at: Date.current)

      get viability_audit_path
      expect(response.body).to include("No active seed purchases to audit")
    end

    it "shows filtered empty message when filters match nothing" do
      get viability_audit_path(year_from: 1900, year_to: 1901)
      expect(response.body).to include("No purchases match the current filters")
    end
  end
end
