require "rails_helper"

RSpec.describe BulkGrowingGuideResearchJob, type: :job do
  let!(:plant_type) { create(:plant_type, name: "Vegetable") }

  let!(:category_without_guide) { create(:plant_category, name: "Tomato", plant_type: plant_type) }
  let!(:category_with_guide) { create(:plant_category, name: "Pepper", plant_type: plant_type) }
  let!(:subcategory_without_guide) { create(:plant_subcategory, name: "Cherry", plant_category: category_without_guide) }
  let!(:subcategory_with_guide) { create(:plant_subcategory, name: "Bell", plant_category: category_with_guide) }

  before do
    create(:growing_guide, plant_category: category_with_guide)
    create(:growing_guide, :for_subcategory, plant_subcategory: subcategory_with_guide)
  end

  describe "#perform" do
    it "enqueues GrowingGuideResearchJob for categories missing guides" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(GrowingGuideResearchJob).with(category_without_guide.id, "PlantCategory")
    end

    it "enqueues GrowingGuideResearchJob for subcategories missing guides" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(GrowingGuideResearchJob).with(subcategory_without_guide.id, "PlantSubcategory")
    end

    it "does not enqueue jobs for categories that already have guides" do
      described_class.perform_now

      expect(GrowingGuideResearchJob).not_to have_been_enqueued.with(category_with_guide.id, "PlantCategory")
    end

    it "does not enqueue jobs for subcategories that already have guides" do
      described_class.perform_now

      expect(GrowingGuideResearchJob).not_to have_been_enqueued.with(subcategory_with_guide.id, "PlantSubcategory")
    end

    it "returns the total count of enqueued jobs" do
      result = described_class.perform_now
      expect(result).to eq(2)
    end

    it "enqueues no jobs when all have guides" do
      create(:growing_guide, plant_category: category_without_guide)
      create(:growing_guide, :for_subcategory, plant_subcategory: subcategory_without_guide)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_job(GrowingGuideResearchJob)
    end
  end

  describe "job enqueueing" do
    it "enqueues on the default queue" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end
end
