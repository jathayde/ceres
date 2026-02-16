FactoryBot.define do
  factory :seed_source do
    sequence(:name) { |n| "Seed Source #{n}" }
    url { Faker::Internet.url }
    notes { Faker::Lorem.sentence }
  end
end
