FactoryBot.define do
  factory :buy_list_item do
    association :plant_category
    plant_subcategory { nil }
    plant { nil }

    trait :for_subcategory do
      plant_category { nil }
      association :plant_subcategory
    end

    trait :for_plant do
      plant_category { nil }
      association :plant
    end

    trait :purchased do
      status { :purchased }
      purchased_at { Time.current }
      association :seed_purchase
    end
  end
end
