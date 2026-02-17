require "rails_helper"

RSpec.describe Plant, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant_category) }
    it { is_expected.to belong_to(:plant_subcategory).optional }
    it { is_expected.to have_one(:growing_guide).dependent(:destroy) }
    it { is_expected.to have_many(:seed_purchases).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:seed_sources).through(:seed_purchases) }
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

  describe "#deletable?" do
    it "returns true when plant has no seed purchases" do
      plant = create(:plant)
      expect(plant.deletable?).to be true
    end

    it "returns false when plant has seed purchases" do
      plant = create(:plant)
      create(:seed_purchase, plant: plant)
      expect(plant.deletable?).to be false
    end
  end

  describe "#active_purchases" do
    it "returns purchases that are not used up" do
      plant = create(:plant)
      active = create(:seed_purchase, plant: plant, used_up: false)
      create(:seed_purchase, plant: plant, used_up: true)

      expect(plant.active_purchases).to eq([ active ])
    end
  end

  describe "#best_viability_status" do
    let(:plant_category) { create(:plant_category, expected_viability_years: 5) }
    let(:plant) { create(:plant, plant_category: plant_category) }

    it "returns nil when there are no active purchases" do
      expect(plant.best_viability_status).to be_nil
    end

    it "returns :viable when any active purchase is viable" do
      create(:seed_purchase, plant: plant, year_purchased: Date.current.year)
      expect(plant.best_viability_status).to eq(:viable)
    end

    it "returns :test when best status is test" do
      create(:seed_purchase, plant: plant, year_purchased: Date.current.year - 6)
      expect(plant.best_viability_status).to eq(:test)
    end

    it "returns :expired when all active purchases are expired" do
      create(:seed_purchase, plant: plant, year_purchased: Date.current.year - 8)
      expect(plant.best_viability_status).to eq(:expired)
    end

    it "ignores used_up purchases" do
      create(:seed_purchase, plant: plant, year_purchased: Date.current.year, used_up: true)
      expect(plant.best_viability_status).to be_nil
    end
  end

  describe ".search" do
    it "finds plants by name" do
      tomato = create(:plant, name: "Cherokee Purple")
      create(:plant, name: "Genovese Basil")

      results = Plant.search("Cherokee")
      expect(results).to include(tomato)
      expect(results.size).to eq(1)
    end

    it "finds plants by latin name" do
      tomato = create(:plant, name: "Roma", latin_name: "Solanum lycopersicum")
      create(:plant, name: "Sweet Basil")

      results = Plant.search("Solanum")
      expect(results).to include(tomato)
    end

    it "finds plants by notes" do
      plant = create(:plant, name: "Jalapeno", notes: "Great for salsa and pickling")
      create(:plant, name: "Bell Pepper")

      results = Plant.search("salsa")
      expect(results).to include(plant)
    end

    it "finds plants by seed source name" do
      source = create(:seed_source, name: "Baker Creek Heirloom")
      plant = create(:plant, name: "Moon and Stars")
      create(:seed_purchase, plant: plant, seed_source: source)
      create(:plant, name: "Sugar Baby")

      results = Plant.search("Baker")
      expect(results).to include(plant)
    end

    it "supports prefix matching" do
      plant = create(:plant, name: "Brandywine")
      results = Plant.search("Brand")
      expect(results).to include(plant)
    end

    it "is case insensitive" do
      plant = create(:plant, name: "Sun Gold")
      results = Plant.search("sun gold")
      expect(results).to include(plant)
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
