FactoryBot.define do
  factory :plant_category do
    plant_type
    sequence(:name) { |n| "Plant Category #{n}" }
    latin_genus { Faker::Lorem.word.capitalize }
    latin_species { Faker::Lorem.word }
    expected_viability_years { rand(2..6) }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
  end
end
