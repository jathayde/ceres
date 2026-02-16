require "rails_helper"

RSpec.describe Plant, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant_category) }
    it { is_expected.to belong_to(:plant_subcategory).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:life_cycle) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:winter_hardy)
        .with_values(hardy: 0, semi_hardy: 1, tender: 2)
    }

    it {
      is_expected.to define_enum_for(:life_cycle)
        .with_values(annual: 0, biennial: 1, perennial: 2)
    }
  end

  describe "optional subcategory" do
    it "is valid without a plant_subcategory" do
      plant = build(:plant, plant_subcategory: nil)
      expect(plant).to be_valid
    end

    it "is valid with a plant_subcategory" do
      subcategory = create(:plant_subcategory)
      plant = build(:plant, plant_category: subcategory.plant_category, plant_subcategory: subcategory)
      expect(plant).to be_valid
    end
  end

  describe "defaults" do
    it "defaults heirloom to false" do
      plant = Plant.new
      expect(plant.heirloom).to be false
    end
  end

  describe "factory" do
    it "creates a valid plant" do
      plant = build(:plant)
      expect(plant).to be_valid
    end

    it "creates unique names with sequences" do
      p1 = create(:plant)
      p2 = create(:plant)
      expect(p1.name).not_to eq(p2.name)
    end
  end
end
