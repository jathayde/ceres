require "rails_helper"

RSpec.describe PlantType, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:plant_categories).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:plants).through(:plant_categories) }
  end

  describe "validations" do
    subject { create(:plant_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "slug" do
    it "generates a slug from the name" do
      plant_type = PlantType.new(name: "Vegetable")
      plant_type.valid?
      expect(plant_type.slug).to eq("vegetable")
    end

    it "parameterizes multi-word names" do
      plant_type = PlantType.new(name: "Cover Crop")
      plant_type.valid?
      expect(plant_type.slug).to eq("cover-crop")
    end

    it "uses slug as to_param" do
      plant_type = create(:plant_type, name: "Vegetable")
      expect(plant_type.to_param).to eq("vegetable")
    end

    it "updates slug when name changes" do
      plant_type = create(:plant_type, name: "Vegetable")
      plant_type.name = "Fruit"
      plant_type.valid?
      expect(plant_type.slug).to eq("fruit")
    end
  end

  describe "default scope" do
    it "orders by position" do
      third = PlantType.create!(name: "Third", position: 3)
      first = PlantType.create!(name: "First", position: 1)
      second = PlantType.create!(name: "Second", position: 2)

      expect(PlantType.all.to_a).to eq([ first, second, third ])
    end
  end

  describe "#deletable?" do
    it "returns true when there are no categories" do
      plant_type = create(:plant_type)
      expect(plant_type.deletable?).to be true
    end

    it "returns false when there are categories" do
      plant_type = create(:plant_type)
      create(:plant_category, plant_type: plant_type)
      expect(plant_type.deletable?).to be false
    end
  end

  describe "factory" do
    it "creates a valid plant type" do
      plant_type = build(:plant_type)
      expect(plant_type).to be_valid
    end

    it "creates unique names with sequences" do
      pt1 = create(:plant_type)
      pt2 = create(:plant_type)
      expect(pt1.name).not_to eq(pt2.name)
    end
  end
end
