require "rails_helper"

RSpec.describe PlantSubcategory, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant_category) }
  end

  describe "validations" do
    subject { build(:plant_subcategory) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:plant_category_id) }
  end

  describe "default scope" do
    it "orders by position" do
      plant_category = create(:plant_category)
      third = create(:plant_subcategory, plant_category: plant_category, position: 3)
      first = create(:plant_subcategory, plant_category: plant_category, position: 1)
      second = create(:plant_subcategory, plant_category: plant_category, position: 2)

      expect(PlantSubcategory.where(plant_category: plant_category).to_a).to eq([ first, second, third ])
    end
  end

  describe "scoped uniqueness" do
    it "allows the same name in different plant categories" do
      category_a = create(:plant_category, name: "Category A")
      category_b = create(:plant_category, name: "Category B")

      create(:plant_subcategory, plant_category: category_a, name: "Bush")
      subcategory_b = build(:plant_subcategory, plant_category: category_b, name: "Bush")

      expect(subcategory_b).to be_valid
    end

    it "rejects duplicate names within the same plant category" do
      plant_category = create(:plant_category)
      create(:plant_subcategory, plant_category: plant_category, name: "Bush")
      duplicate = build(:plant_subcategory, plant_category: plant_category, name: "Bush")

      expect(duplicate).not_to be_valid
    end
  end

  describe "factory" do
    it "creates a valid plant subcategory" do
      plant_subcategory = build(:plant_subcategory)
      expect(plant_subcategory).to be_valid
    end

    it "creates unique names with sequences" do
      ps1 = create(:plant_subcategory)
      ps2 = create(:plant_subcategory)
      expect(ps1.name).not_to eq(ps2.name)
    end
  end
end
