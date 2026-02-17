require "rails_helper"

RSpec.describe PlantCategory, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant_type) }
    it { is_expected.to have_one(:growing_guide).dependent(:destroy) }
    it { is_expected.to have_many(:plant_subcategories).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:plants).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { create(:plant_category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:plant_type_id) }
  end

  describe "slug" do
    it "generates a slug from the name" do
      category = PlantCategory.new(name: "Artichoke", plant_type: create(:plant_type))
      category.valid?
      expect(category.slug).to eq("artichoke")
    end

    it "uses slug as to_param" do
      category = create(:plant_category, name: "Artichoke")
      expect(category.to_param).to eq("artichoke")
    end
  end

  describe "default scope" do
    it "orders by name" do
      plant_type = create(:plant_type)
      cherry = create(:plant_category, plant_type: plant_type, name: "Cherry", position: 3)
      apple = create(:plant_category, plant_type: plant_type, name: "Apple", position: 1)
      banana = create(:plant_category, plant_type: plant_type, name: "Banana", position: 2)

      expect(PlantCategory.where(plant_type: plant_type).to_a).to eq([ apple, banana, cherry ])
    end
  end

  describe "#deletable?" do
    it "returns true when there are no plants or subcategories" do
      category = create(:plant_category)
      expect(category.deletable?).to be true
    end

    it "returns false when there are plants" do
      category = create(:plant_category)
      create(:plant, plant_category: category)
      expect(category.deletable?).to be false
    end

    it "returns false when there are subcategories" do
      category = create(:plant_category)
      create(:plant_subcategory, plant_category: category)
      expect(category.deletable?).to be false
    end
  end

  describe "scoped uniqueness" do
    it "allows the same name in different plant types" do
      type_a = create(:plant_type, name: "Type A")
      type_b = create(:plant_type, name: "Type B")

      create(:plant_category, plant_type: type_a, name: "Bean")
      category_b = build(:plant_category, plant_type: type_b, name: "Bean")

      expect(category_b).to be_valid
    end

    it "rejects duplicate names within the same plant type" do
      plant_type = create(:plant_type)
      create(:plant_category, plant_type: plant_type, name: "Bean")
      duplicate = build(:plant_category, plant_type: plant_type, name: "Bean")

      expect(duplicate).not_to be_valid
    end
  end

  describe "factory" do
    it "creates a valid plant category" do
      plant_category = build(:plant_category)
      expect(plant_category).to be_valid
    end

    it "creates unique names with sequences" do
      pc1 = create(:plant_category)
      pc2 = create(:plant_category)
      expect(pc1.name).not_to eq(pc2.name)
    end
  end
end
