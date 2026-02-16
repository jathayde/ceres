require "rails_helper"

RSpec.describe GrowingGuide, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:plant) }
  end

  describe "validations" do
    subject { build(:growing_guide) }

    it { is_expected.to validate_uniqueness_of(:plant_id) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:sun_exposure)
        .with_values(full_sun: 0, partial_shade: 1, full_shade: 2)
    }

    it {
      is_expected.to define_enum_for(:water_needs)
        .with_values(low: 0, moderate: 1, high: 2)
    }
  end

  describe "unique plant constraint" do
    it "does not allow two growing guides for the same plant" do
      plant = create(:plant)
      create(:growing_guide, plant: plant)
      duplicate = build(:growing_guide, plant: plant)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:plant_id]).to include("has already been taken")
    end
  end

  describe "defaults" do
    it "defaults ai_generated to false" do
      guide = GrowingGuide.new
      expect(guide.ai_generated).to be false
    end
  end

  describe "factory" do
    it "creates a valid growing guide" do
      guide = build(:growing_guide)
      expect(guide).to be_valid
    end
  end
end
