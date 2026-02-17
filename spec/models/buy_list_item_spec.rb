require "rails_helper"

RSpec.describe BuyListItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant_category).optional }
    it { is_expected.to belong_to(:plant_subcategory).optional }
    it { is_expected.to belong_to(:plant).optional }
    it { is_expected.to belong_to(:seed_purchase).optional }
  end

  describe "validations" do
    it "requires exactly one target" do
      item = build(:buy_list_item, plant_category: nil, plant_subcategory: nil, plant: nil)
      expect(item).not_to be_valid
      expect(item.errors[:base]).to include("must belong to a plant category, plant subcategory, or plant")
    end

    it "clears redundant targets via before_validation" do
      category = create(:plant_category)
      subcategory = create(:plant_subcategory)
      item = build(:buy_list_item, plant_category: category, plant_subcategory: subcategory)
      item.valid?
      expect(item.plant_category_id).to be_nil
      expect(item.plant_subcategory_id).to eq(subcategory.id)
    end

    it "is valid with only a plant_category" do
      item = build(:buy_list_item, plant_category: create(:plant_category))
      expect(item).to be_valid
    end

    it "is valid with only a plant_subcategory" do
      item = build(:buy_list_item, plant_category: nil, plant_subcategory: create(:plant_subcategory))
      expect(item).to be_valid
    end

    it "is valid with only a plant" do
      item = build(:buy_list_item, plant_category: nil, plant: create(:plant))
      expect(item).to be_valid
    end
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(pending: 0, purchased: 1)
    }
  end

  describe "scopes" do
    let!(:pending_item) { create(:buy_list_item) }
    let!(:purchased_item) { create(:buy_list_item, :purchased) }

    it ".pending returns only pending items" do
      expect(described_class.pending).to contain_exactly(pending_item)
    end

    it ".purchased returns only purchased items" do
      expect(described_class.purchased).to contain_exactly(purchased_item)
    end
  end

  describe "#target" do
    it "returns plant when present" do
      plant = create(:plant)
      item = create(:buy_list_item, :for_plant, plant: plant)
      expect(item.target).to eq(plant)
    end

    it "returns subcategory when present" do
      subcategory = create(:plant_subcategory)
      item = create(:buy_list_item, :for_subcategory, plant_subcategory: subcategory)
      expect(item.target).to eq(subcategory)
    end

    it "returns category when present" do
      category = create(:plant_category)
      item = create(:buy_list_item, plant_category: category)
      expect(item.target).to eq(category)
    end
  end

  describe "#target_name" do
    it "returns the name of the target" do
      category = create(:plant_category, name: "Tomatoes")
      item = create(:buy_list_item, plant_category: category)
      expect(item.target_name).to eq("Tomatoes")
    end
  end

  describe "#target_level" do
    it "returns :variety for plant items" do
      item = create(:buy_list_item, :for_plant)
      expect(item.target_level).to eq(:variety)
    end

    it "returns :subcategory for subcategory items" do
      item = create(:buy_list_item, :for_subcategory)
      expect(item.target_level).to eq(:subcategory)
    end

    it "returns :category for category items" do
      item = create(:buy_list_item)
      expect(item.target_level).to eq(:category)
    end
  end

  describe "#needs_variety_selection?" do
    it "returns true for category items" do
      item = create(:buy_list_item)
      expect(item.needs_variety_selection?).to be true
    end

    it "returns true for subcategory items" do
      item = create(:buy_list_item, :for_subcategory)
      expect(item.needs_variety_selection?).to be true
    end

    it "returns false for plant items" do
      item = create(:buy_list_item, :for_plant)
      expect(item.needs_variety_selection?).to be false
    end
  end

  describe "#mark_purchased!" do
    it "updates status, purchased_at, and seed_purchase" do
      item = create(:buy_list_item)
      purchase = create(:seed_purchase)

      item.mark_purchased!(purchase)

      expect(item.reload).to be_purchased
      expect(item.purchased_at).to be_present
      expect(item.seed_purchase).to eq(purchase)
    end
  end

  describe "factory" do
    it "creates a valid buy list item" do
      item = create(:buy_list_item)
      expect(item).to be_valid
    end

    it "creates a valid subcategory buy list item" do
      item = create(:buy_list_item, :for_subcategory)
      expect(item).to be_valid
    end

    it "creates a valid plant buy list item" do
      item = create(:buy_list_item, :for_plant)
      expect(item).to be_valid
    end

    it "creates a valid purchased buy list item" do
      item = create(:buy_list_item, :purchased)
      expect(item).to be_valid
      expect(item).to be_purchased
    end
  end
end
