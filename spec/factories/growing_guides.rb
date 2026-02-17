FactoryBot.define do
  factory :growing_guide do
    association :plant_category
    plant_subcategory { nil }
    ai_generated { false }

    trait :for_subcategory do
      plant_category { nil }
      association :plant_subcategory
    end
  end
end
