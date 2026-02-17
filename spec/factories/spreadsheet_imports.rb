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
