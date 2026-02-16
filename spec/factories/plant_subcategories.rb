FactoryBot.define do
  factory :plant_subcategory do
    plant_category
    sequence(:name) { |n| "Plant Subcategory #{n}" }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
  end
end
