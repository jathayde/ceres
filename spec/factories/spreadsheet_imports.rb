FactoryBot.define do
  factory :spreadsheet_import do
    original_filename { "seed_inventory.xlsx" }
    status { :pending }
    total_rows { 0 }
    parsed_rows { 0 }
    sheet_names { [] }

    trait :parsing do
      status { :parsing }
      total_rows { 100 }
      parsed_rows { 50 }
      sheet_names { [ "Vegetables", "Herbs" ] }
    end

    trait :parsed do
      status { :parsed }
      total_rows { 100 }
      parsed_rows { 100 }
      sheet_names { [ "Vegetables", "Grains", "Herbs", "Flowers", "Cover Crops" ] }
    end

    trait :failed do
      status { :failed }
      error_message { "Invalid file format" }
    end

    trait :mapping do
      status { :mapping }
      total_rows { 100 }
      parsed_rows { 100 }
      mapped_rows { 50 }
      sheet_names { [ "Vegetables", "Herbs" ] }
    end

    trait :mapped do
      status { :mapped }
      total_rows { 100 }
      parsed_rows { 100 }
      mapped_rows { 100 }
      sheet_names { [ "Vegetables", "Grains", "Herbs", "Flowers", "Cover Crops" ] }
    end

    trait :executing do
      status { :executing }
      total_rows { 100 }
      parsed_rows { 100 }
      mapped_rows { 100 }
      executed_rows { 50 }
      sheet_names { [ "Vegetables", "Herbs" ] }
    end

    trait :executed do
      status { :executed }
      total_rows { 100 }
      parsed_rows { 100 }
      mapped_rows { 100 }
      executed_rows { 80 }
      import_report { { "plants_created" => 30, "purchases_created" => 80, "sources_created" => 5, "categories_created" => 2, "subcategories_created" => 1, "rows_skipped" => 0, "errors" => [] } }
      sheet_names { [ "Vegetables", "Grains", "Herbs", "Flowers", "Cover Crops" ] }
    end

    trait :with_file do
      after(:build) do |import|
        import.file.attach(
          io: StringIO.new("fake xlsx content"),
          filename: import.original_filename,
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end
  end
end
