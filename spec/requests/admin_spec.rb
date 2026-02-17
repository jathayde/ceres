require "rails_helper"

RSpec.describe "Admin", type: :request do
  let!(:plant_type) { create(:plant_type, name: "Vegetable") }
  let!(:category_without_guide) { create(:plant_category, name: "Tomato", plant_type: plant_type) }
  let!(:category_with_guide) { create(:plant_category, name: "Pepper", plant_type: plant_type) }
  let!(:subcategory_without_guide) { create(:plant_subcategory, name: "Cherry", plant_category: category_without_guide) }

  before do
    create(:growing_guide, plant_category: category_with_guide)
  end

  describe "GET /admin" do
    it "returns a successful response" do
      get admin_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the Settings header" do
      get admin_path
      expect(response.body).to include("Settings")
    end

    it "shows the count of categories missing guides" do
      get admin_path
      expect(response.body).to include("2")
    end

    it "shows the Research All Growing Guides button" do
      get admin_path
      expect(response.body).to include("Research All Growing Guides")
    end

    context "when all categories have guides" do
      before do
        create(:growing_guide, plant_category: category_without_guide)
        create(:growing_guide, :for_subcategory, plant_subcategory: subcategory_without_guide)
      end

      it "shows all-complete message" do
        get admin_path
        expect(response.body).to include("All categories and subcategories have growing guides")
      end
    end
  end

  describe "POST /admin/research_all_growing_guides" do
    it "enqueues BulkGrowingGuideResearchJob" do
      expect {
        post admin_research_all_growing_guides_path
      }.to have_enqueued_job(BulkGrowingGuideResearchJob)
    end

    it "redirects to admin page with notice" do
      post admin_research_all_growing_guides_path
      expect(response).to redirect_to(admin_path)
      follow_redirect!
      expect(response.body).to include("Enqueued growing guide research for 2 categories")
    end
  end
end
