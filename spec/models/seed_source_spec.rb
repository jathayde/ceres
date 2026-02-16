require "rails_helper"

RSpec.describe SeedSource, type: :model do
  describe "validations" do
    subject { build(:seed_source) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
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
