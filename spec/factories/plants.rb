FactoryBot.define do
  factory :plant do
    plant_category
    plant_subcategory { nil }
    sequence(:name) { |n| "Plant Variety #{n}" }
    life_cycle { :annual }
    heirloom { false }
  end
end
