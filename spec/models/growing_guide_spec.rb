require "rails_helper"

RSpec.describe GrowingGuide, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant_category).optional }
    it { is_expected.to belong_to(:plant_subcategory).optional }
  end

  describe "validations" do
    it "requires exactly one of plant_category or plant_subcategory" do
      guide = build(:growing_guide, plant_category: nil, plant_subcategory: nil)
      expect(guide).not_to be_valid
      expect(guide.errors[:base]).to include("must belong to a plant category or plant subcategory")
    end

    it "does not allow both plant_category and plant_subcategory" do
      guide = build(:growing_guide, plant_category: create(:plant_category), plant_subcategory: create(:plant_subcategory))
      expect(guide).not_to be_valid
      expect(guide.errors[:base]).to include("cannot belong to both a plant category and a plant subcategory")
    end

    it "does not allow two growing guides for the same category" do
      category = create(:plant_category)
      create(:growing_guide, plant_category: category)
      duplicate = build(:growing_guide, plant_category: category)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plant_category_id]).to include("has already been taken")
    end

    it "does not allow two growing guides for the same subcategory" do
      subcategory = create(:plant_subcategory)
      create(:growing_guide, :for_subcategory, plant_subcategory: subcategory)
      duplicate = build(:growing_guide, :for_subcategory, plant_subcategory: subcategory)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plant_subcategory_id]).to include("has already been taken")
    end
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:sun_exposure)
        .with_values(full_sun: 0, partial_shade: 1, full_shade: 2)
    }

    it {
      is_expected.to define_enum_for(:water_needs)
        .with_values(low: 0, moderate: 1, high: 2)
    }
  end

  describe "#guideable" do
    it "returns the subcategory when present" do
      subcategory = create(:plant_subcategory)
      guide = create(:growing_guide, :for_subcategory, plant_subcategory: subcategory)
      expect(guide.guideable).to eq(subcategory)
    end

    it "returns the category when no subcategory" do
      category = create(:plant_category)
      guide = create(:growing_guide, plant_category: category)
      expect(guide.guideable).to eq(category)
    end
  end

  describe "defaults" do
    it "defaults ai_generated to false" do
      guide = GrowingGuide.new
      expect(guide.ai_generated).to be false
    end
  end

  describe "factory" do
    it "creates a valid growing guide" do
      guide = create(:growing_guide)
      expect(guide).to be_valid
    end

    it "creates a valid growing guide for subcategory" do
      guide = create(:growing_guide, :for_subcategory)
      expect(guide).to be_valid
    end
  end
end
