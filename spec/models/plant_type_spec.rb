require "rails_helper"

RSpec.describe PlantType, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:plant_categories).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:plant_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "default scope" do
    it "orders by position" do
      third = PlantType.create!(name: "Third", position: 3)
      first = PlantType.create!(name: "First", position: 1)
      second = PlantType.create!(name: "Second", position: 2)

      expect(PlantType.all.to_a).to eq([ first, second, third ])
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
