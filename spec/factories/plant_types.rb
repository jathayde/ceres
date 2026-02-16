FactoryBot.define do
  factory :plant_type do
    sequence(:name) { |n| "Plant Type #{n}" }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
  end
end
