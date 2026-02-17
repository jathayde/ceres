require "rails_helper"

RSpec.describe SeedSource, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:seed_purchases).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { build(:seed_source) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "default scope" do
    it "orders by name alphabetically" do
      zephyr = create(:seed_source, name: "Zephyr Seeds")
      alpine = create(:seed_source, name: "Alpine Seeds")
      middle = create(:seed_source, name: "Middle Ground")

      expect(SeedSource.all).to eq([ alpine, middle, zephyr ])
    end
  end

  describe "#active_purchases_count" do
    it "returns the count of non-used-up purchases" do
      seed_source = create(:seed_source)
      create(:seed_purchase, seed_source: seed_source, used_up: false)
      create(:seed_purchase, seed_source: seed_source, used_up: false)
      create(:seed_purchase, seed_source: seed_source, used_up: true)

      expect(seed_source.active_purchases_count).to eq(2)
    end

    it "returns 0 when there are no purchases" do
      seed_source = create(:seed_source)
      expect(seed_source.active_purchases_count).to eq(0)
    end
  end

  describe "#deletable?" do
    it "returns true when there are no purchases" do
      seed_source = create(:seed_source)
      expect(seed_source.deletable?).to be true
    end

    it "returns false when there are purchases" do
      seed_source = create(:seed_source)
      create(:seed_purchase, seed_source: seed_source)
      expect(seed_source.deletable?).to be false
    end
  end

  describe "factory" do
    it "creates a valid seed source" do
      seed_source = build(:seed_source)
      expect(seed_source).to be_valid
    end

    it "creates unique names with sequences" do
      ss1 = create(:seed_source)
      ss2 = create(:seed_source)
      expect(ss1.name).not_to eq(ss2.name)
    end
  end
end
