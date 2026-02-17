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

  describe "#merge_with!" do
    it "reassigns all purchases from other sources to the primary" do
      primary = create(:seed_source, name: "Primary Source")
      other = create(:seed_source, name: "Duplicate Source")
      purchase1 = create(:seed_purchase, seed_source: primary)
      purchase2 = create(:seed_purchase, seed_source: other)
      purchase3 = create(:seed_purchase, seed_source: other)

      primary.merge_with!([ other ])

      expect(purchase2.reload.seed_source).to eq(primary)
      expect(purchase3.reload.seed_source).to eq(primary)
      expect(purchase1.reload.seed_source).to eq(primary)
    end

    it "deletes the merged source records" do
      primary = create(:seed_source, name: "Primary Source")
      other1 = create(:seed_source, name: "Duplicate 1")
      other2 = create(:seed_source, name: "Duplicate 2")

      expect {
        primary.merge_with!([ other1, other2 ])
      }.to change(SeedSource, :count).by(-2)
    end

    it "preserves the primary source record" do
      primary = create(:seed_source, name: "Primary Source")
      other = create(:seed_source, name: "Duplicate Source")

      primary.merge_with!([ other ])

      expect(SeedSource.exists?(primary.id)).to be true
    end

    it "handles merging a source with no purchases" do
      primary = create(:seed_source, name: "Primary Source")
      other = create(:seed_source, name: "Empty Source")

      expect {
        primary.merge_with!([ other ])
      }.to change(SeedSource, :count).by(-1)
    end

    it "handles a single source to merge" do
      primary = create(:seed_source, name: "Primary Source")
      other = create(:seed_source, name: "Duplicate Source")
      purchase = create(:seed_purchase, seed_source: other)

      primary.merge_with!(other)

      expect(purchase.reload.seed_source).to eq(primary)
      expect(SeedSource.exists?(other.id)).to be false
    end

    it "raises an error when trying to merge a source with itself" do
      source = create(:seed_source)
      expect { source.merge_with!(source) }.to raise_error(ArgumentError, "cannot merge a source with itself")
    end

    it "wraps the operation in a transaction" do
      primary = create(:seed_source, name: "Primary Source")
      other = create(:seed_source, name: "Duplicate Source")
      create(:seed_purchase, seed_source: other)

      allow(SeedSource).to receive(:find).and_return(other)
      allow(other).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      expect {
        primary.merge_with!([ other ]) rescue nil
      }.not_to change(SeedPurchase, :count)
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
