FactoryBot.define do
  factory :spreadsheet_import_row do
    spreadsheet_import
    sheet_name { "Vegetables" }
    sequence(:row_number) { |n| n + 1 }
    variety_name { Faker::Food.vegetables }
    seed_source_name { Faker::Company.name }
    year_purchased { rand(2010..2025) }
    raw_date_value { year_purchased.to_s }
    notes { Faker::Lorem.sentence }
    detected_used_up { false }
    has_gray_text { false }
    raw_data { { "Variety" => variety_name, "Source" => seed_source_name, "Year" => year_purchased.to_s } }
    parse_warnings { [] }

    trait :used_up do
      detected_used_up { true }
      has_gray_text { true }
    end

    trait :with_germination do
      germination_rate { 0.85 }
      raw_germination_value { "85%" }
    end

    trait :with_warnings do
      parse_warnings { [ "Could not parse year from 'sometime in 2020'" ] }
    end

    trait :ai_mapped do
      mapping_status { :ai_mapped }
      mapped_plant_type_name { "Vegetable" }
      mapped_category_name { "Tomato" }
      mapped_source_name { seed_source_name }
      mapping_confidence { 0.92 }
      ai_mapping_data { { plant_type: "Vegetable", category: "Tomato", confidence: 0.92 } }
    end

    trait :accepted do
      ai_mapped
      mapping_status { :accepted }
    end

    trait :modified do
      ai_mapped
      mapping_status { :modified }
    end

    trait :rejected do
      ai_mapped
      mapping_status { :rejected }
    end
  end
end
