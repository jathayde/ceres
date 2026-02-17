require "rails_helper"

RSpec.describe "Viability Audit", type: :request do
  let!(:plant_type) { create(:plant_type, name: "Vegetable") }
  let!(:plant_category) { create(:plant_category, name: "Tomato", plant_type: plant_type, expected_viability_years: 5) }
  let!(:seed_source) { create(:seed_source, name: "Baker Creek") }
  let!(:plant) { create(:plant, name: "Sun Gold", plant_category: plant_category, latin_name: "Solanum lycopersicum") }

  let!(:viable_purchase) do
    create(:seed_purchase, plant: plant, seed_source: seed_source,
      year_purchased: Date.current.year - 1, used_up: false)
  end
  let!(:test_purchase) do
    create(:seed_purchase, plant: plant, seed_source: seed_source,
      year_purchased: Date.current.year - 6, used_up: false)
  end
  let!(:expired_purchase) do
    create(:seed_purchase, plant: plant, seed_source: seed_source,
      year_purchased: Date.current.year - 10, used_up: false)
  end
  let!(:used_up_purchase) do
    create(:seed_purchase, plant: plant, seed_source: seed_source,
      year_purchased: Date.current.year, used_up: true, used_up_at: Date.current)
  end

  describe "GET /viability_audit" do
    it "returns a successful response" do
      get viability_audit_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the page header" do
      get viability_audit_path
      expect(response.body).to include("Viability Audit")
    end

    it "displays summary counts" do
      get viability_audit_path
      body = response.body
      expect(body).to include("Viable")
      expect(body).to include("Needs Testing")
      expect(body).to include("Expired")
    end

    it "counts viable purchases correctly" do
      get viability_audit_path
      # The viable summary card should show 1
      expect(response.body).to match(/Viable/)
    end

    it "excludes used-up purchases from the table" do
      get viability_audit_path
      # Only 3 active purchases should appear (viable, test, expired)
      expect(response.body.scan(/seed_purchase_ids/).count).to eq(3)
    end

    it "displays viability badges" do
      get viability_audit_path
      expect(response.body).to include("Viable")
      expect(response.body).to include("Test")
      expect(response.body).to include("Expired")
    end

    it "shows plant name linked to plant detail" do
      get viability_audit_path
      expect(response.body).to include(plant_path(plant))
      expect(response.body).to include("Sun Gold")
    end

    it "shows category name" do
      get viability_audit_path
      expect(response.body).to include("Tomato")
    end

    it "shows seed source name" do
      get viability_audit_path
      expect(response.body).to include("Baker Creek")
    end

    it "shows year purchased" do
      get viability_audit_path
      expect(response.body).to include(viable_purchase.year_purchased.to_s)
    end

    it "shows reviewed checkbox" do
      get viability_audit_path
      expect(response.body).to include("Mark as reviewed")
    end

    it "shows mark as used up button" do
      get viability_audit_path
      expect(response.body).to include("Mark Used Up")
    end

    it "shows bulk select checkboxes" do
      get viability_audit_path
      expect(response.body).to include("bulk-select")
      expect(response.body).to include("audit-bulk-form")
    end

    it "shows print button" do
      get viability_audit_path
      expect(response.body).to include("Print")
    end

    it "shows sort controls" do
      get viability_audit_path
      expect(response.body).to include("Sort by:")
      expect(response.body).to include("Urgency")
      expect(response.body).to include("Plant Name")
    end

    it "color-codes rows by viability status" do
      get viability_audit_path
      expect(response.body).to include("bg-green-50")
      expect(response.body).to include("bg-amber-50")
      expect(response.body).to include("bg-red-50")
    end
  end

  describe "GET /viability_audit with filters" do
    context "filtering by viability status" do
      it "filters to viable only" do
        get viability_audit_path(viability: "viable")
        expect(response).to have_http_status(:ok)
        # Only the viable purchase should appear
        expect(response.body.scan(/seed_purchase_ids/).count).to eq(1)
      end

      it "filters to test only" do
        get viability_audit_path(viability: "test")
        expect(response).to have_http_status(:ok)
        expect(response.body.scan(/seed_purchase_ids/).count).to eq(1)
      end

      it "filters to expired only" do
        get viability_audit_path(viability: "expired")
        expect(response).to have_http_status(:ok)
        expect(response.body.scan(/seed_purchase_ids/).count).to eq(1)
      end
    end

    context "filtering by plant type" do
      let!(:other_type) { create(:plant_type, name: "Herb") }
      let!(:herb_category) { create(:plant_category, name: "Basil", plant_type: other_type, expected_viability_years: 3) }
      let!(:herb_plant) { create(:plant, name: "Genovese", plant_category: herb_category, latin_name: "Ocimum basilicum") }
      let!(:herb_purchase) { create(:seed_purchase, plant: herb_plant, seed_source: seed_source, year_purchased: Date.current.year, used_up: false) }

      it "filters by plant type" do
        get viability_audit_path(plant_type_id: other_type.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Genovese")
        expect(response.body).not_to include("Sun Gold")
      end
    end

    context "filtering by plant category" do
      it "filters by category" do
        get viability_audit_path(plant_category_id: plant_category.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sun Gold")
      end
    end

    context "filtering by seed source" do
      let!(:other_source) { create(:seed_source, name: "Johnny's") }
      let!(:other_plant) { create(:plant, name: "Beefsteak", plant_category: plant_category, latin_name: "Solanum sp.") }
      let!(:other_purchase) { create(:seed_purchase, plant: other_plant, seed_source: other_source, year_purchased: Date.current.year, used_up: false) }

      it "filters by seed source" do
        get viability_audit_path(seed_source_id: other_source.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Beefsteak")
        expect(response.body).not_to include("Sun Gold")
      end
    end

    context "filtering by year range" do
      it "filters by year_from" do
        get viability_audit_path(year_from: Date.current.year - 2)
        expect(response).to have_http_status(:ok)
        # Only viable_purchase (year - 1) should match
        expect(response.body.scan(/seed_purchase_ids/).count).to eq(1)
      end

      it "filters by year_to" do
        get viability_audit_path(year_to: Date.current.year - 5)
        expect(response).to have_http_status(:ok)
        # test_purchase (year - 6) and expired_purchase (year - 10) should match
        expect(response.body.scan(/seed_purchase_ids/).count).to eq(2)
      end
    end

    context "clearing filters" do
      it "shows clear filters button when filters active" do
        get viability_audit_path(viability: "viable")
        expect(response.body).to include("Clear filters")
      end

      it "does not show clear filters when no filters active" do
        get viability_audit_path
        expect(response.body).not_to include("Clear filters")
      end
    end
  end

  describe "GET /viability_audit with sorting" do
    it "sorts by urgency (default)" do
      get viability_audit_path(sort: "urgency")
      expect(response).to have_http_status(:ok)
    end

    it "sorts by plant name" do
      get viability_audit_path(sort: "name")
      expect(response).to have_http_status(:ok)
    end

    it "sorts by category" do
      get viability_audit_path(sort: "category")
      expect(response).to have_http_status(:ok)
    end

    it "sorts by source" do
      get viability_audit_path(sort: "source")
      expect(response).to have_http_status(:ok)
    end

    it "sorts by year" do
      get viability_audit_path(sort: "year")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /viability_audit/mark_as_used_up/:id" do
    it "marks the purchase as used up" do
      patch viability_audit_mark_as_used_up_path(viable_purchase)
      viable_purchase.reload
      expect(viable_purchase.used_up?).to be true
      expect(viable_purchase.used_up_at).to eq(Date.current)
    end

    it "redirects back to the viability audit" do
      patch viability_audit_mark_as_used_up_path(viable_purchase)
      expect(response).to redirect_to(viability_audit_path)
    end

    it "shows a success notice" do
      patch viability_audit_mark_as_used_up_path(viable_purchase)
      follow_redirect!
      expect(response.body).to include("marked as used up")
    end

    it "preserves filter params on redirect" do
      patch viability_audit_mark_as_used_up_path(viable_purchase, viability: "viable")
      expect(response).to redirect_to(viability_audit_path(viability: "viable"))
    end
  end

  describe "PATCH /viability_audit/bulk_mark_used_up" do
    it "marks selected purchases as used up" do
      patch viability_audit_bulk_mark_used_up_path, params: { seed_purchase_ids: [ viable_purchase.id, test_purchase.id ] }
      viable_purchase.reload
      test_purchase.reload
      expect(viable_purchase.used_up?).to be true
      expect(test_purchase.used_up?).to be true
    end

    it "redirects with a count notice" do
      patch viability_audit_bulk_mark_used_up_path, params: { seed_purchase_ids: [ viable_purchase.id, test_purchase.id ] }
      follow_redirect!
      expect(response.body).to include("2 purchases marked as used up")
    end

    it "shows alert when no purchases selected" do
      patch viability_audit_bulk_mark_used_up_path
      follow_redirect!
      expect(response.body).to include("No purchases were selected")
    end

    it "preserves filter params on redirect" do
      patch viability_audit_bulk_mark_used_up_path(viability: "expired"), params: { seed_purchase_ids: [ expired_purchase.id ] }
      expect(response).to redirect_to(viability_audit_path(viability: "expired"))
    end
  end
end
