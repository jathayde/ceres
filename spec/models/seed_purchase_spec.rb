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
end
