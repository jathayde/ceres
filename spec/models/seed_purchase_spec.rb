require "rails_helper"

RSpec.describe SeedPurchase, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant) }
    it { is_expected.to belong_to(:seed_source) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:year_purchased) }

    describe "germination_rate" do
      it {
        is_expected.to validate_numericality_of(:germination_rate)
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(1)
          .allow_nil
      }

      it "is valid with a germination rate of 0" do
        purchase = build(:seed_purchase, germination_rate: 0)
        expect(purchase).to be_valid
      end

      it "is valid with a germination rate of 1" do
        purchase = build(:seed_purchase, germination_rate: 1)
        expect(purchase).to be_valid
      end

      it "is valid with a germination rate of 0.85" do
        purchase = build(:seed_purchase, germination_rate: 0.85)
        expect(purchase).to be_valid
      end

      it "is invalid with a germination rate greater than 1" do
        purchase = build(:seed_purchase, germination_rate: 1.5)
        expect(purchase).not_to be_valid
      end

      it "is invalid with a negative germination rate" do
        purchase = build(:seed_purchase, germination_rate: -0.1)
        expect(purchase).not_to be_valid
      end

      it "is valid without a germination rate" do
        purchase = build(:seed_purchase, germination_rate: nil)
        expect(purchase).to be_valid
      end
    end
  end

  describe "defaults" do
    it "defaults used_up to false" do
      purchase = SeedPurchase.new
      expect(purchase.used_up).to be false
    end

    it "defaults packet_count to 1" do
      purchase = SeedPurchase.new
      expect(purchase.packet_count).to eq(1)
    end
  end

  describe "factory" do
    it "creates a valid seed purchase" do
      purchase = build(:seed_purchase)
      expect(purchase).to be_valid
    end
  end

  describe "#seed_age" do
    it "calculates age based on current year minus year_purchased" do
      purchase = build(:seed_purchase, year_purchased: Date.current.year - 3)
      expect(purchase.seed_age).to eq(3)
    end

    it "returns 0 for purchases made this year" do
      purchase = build(:seed_purchase, year_purchased: Date.current.year)
      expect(purchase.seed_age).to eq(0)
    end
  end

  describe "#viability_status" do
    let(:plant_category) { build(:plant_category, expected_viability_years: 4) }
    let(:plant) { build(:plant, plant_category: plant_category, expected_viability_years: nil) }

    context "when purchase is used up" do
      it "returns :used_up regardless of age" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 10, used_up: true)
        expect(purchase.viability_status).to eq(:used_up)
      end
    end

    context "when using category-level viability years (plant has no override)" do
      it "returns :viable when age <= expected years" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 3)
        expect(purchase.viability_status).to eq(:viable)
      end

      it "returns :viable when age equals expected years exactly" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 4)
        expect(purchase.viability_status).to eq(:viable)
      end

      it "returns :test when age is 1 year past expected" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 5)
        expect(purchase.viability_status).to eq(:test)
      end

      it "returns :test when age is 2 years past expected" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 6)
        expect(purchase.viability_status).to eq(:test)
      end

      it "returns :expired when age is more than 2 years past expected" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 7)
        expect(purchase.viability_status).to eq(:expired)
      end
    end

    context "when using plant-level viability years override" do
      let(:plant_with_override) { build(:plant, plant_category: plant_category, expected_viability_years: 2) }

      it "uses plant-level override instead of category-level" do
        purchase = build(:seed_purchase, plant: plant_with_override, year_purchased: Date.current.year - 3)
        expect(purchase.viability_status).to eq(:test)
      end

      it "returns :viable within plant override years" do
        purchase = build(:seed_purchase, plant: plant_with_override, year_purchased: Date.current.year - 1)
        expect(purchase.viability_status).to eq(:viable)
      end

      it "returns :expired beyond plant override + 2 years" do
        purchase = build(:seed_purchase, plant: plant_with_override, year_purchased: Date.current.year - 5)
        expect(purchase.viability_status).to eq(:expired)
      end
    end

    context "when neither plant nor category has viability years" do
      let(:category_no_viability) { build(:plant_category, expected_viability_years: nil) }
      let(:plant_no_viability) { build(:plant, plant_category: category_no_viability, expected_viability_years: nil) }

      it "returns :unknown" do
        purchase = build(:seed_purchase, plant: plant_no_viability, year_purchased: Date.current.year - 3)
        expect(purchase.viability_status).to eq(:unknown)
      end
    end

    context "edge cases" do
      it "returns :viable for a purchase made this year" do
        purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year)
        expect(purchase.viability_status).to eq(:viable)
      end
    end
  end

  describe "#viability_years_remaining" do
    let(:plant_category) { build(:plant_category, expected_viability_years: 4) }
    let(:plant) { build(:plant, plant_category: plant_category, expected_viability_years: nil) }

    it "returns positive years when still viable" do
      purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 2)
      expect(purchase.viability_years_remaining).to eq(2)
    end

    it "returns 0 when at the viability boundary" do
      purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 4)
      expect(purchase.viability_years_remaining).to eq(0)
    end

    it "returns negative years when past viability" do
      purchase = build(:seed_purchase, plant: plant, year_purchased: Date.current.year - 6)
      expect(purchase.viability_years_remaining).to eq(-2)
    end

    it "returns nil when no viability years are set" do
      category_no_viability = build(:plant_category, expected_viability_years: nil)
      plant_no_viability = build(:plant, plant_category: category_no_viability, expected_viability_years: nil)
      purchase = build(:seed_purchase, plant: plant_no_viability, year_purchased: Date.current.year - 3)
      expect(purchase.viability_years_remaining).to be_nil
    end

    it "uses plant-level override when present" do
      plant_with_override = build(:plant, plant_category: plant_category, expected_viability_years: 2)
      purchase = build(:seed_purchase, plant: plant_with_override, year_purchased: Date.current.year - 1)
      expect(purchase.viability_years_remaining).to eq(1)
    end
  end
end
