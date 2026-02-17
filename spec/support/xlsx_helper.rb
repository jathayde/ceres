module XlsxHelper
  def create_test_xlsx(sheets: {})
    package = Axlsx::Package.new
    workbook = package.workbook

    gray_style = workbook.styles.add_style(color: "999999")

    sheets.each do |sheet_name, sheet_data|
      workbook.add_worksheet(name: sheet_name) do |sheet|
        headers = sheet_data[:headers]
        sheet.add_row headers

        (sheet_data[:rows] || []).each do |row_data|
          if row_data.is_a?(Hash) && row_data[:gray]
            sheet.add_row row_data[:values], style: gray_style
          else
            values = row_data.is_a?(Hash) ? row_data[:values] : row_data
            sheet.add_row values
          end
        end
      end
    end

    tempfile = Tempfile.new([ "test_import", ".xlsx" ])
    tempfile.binmode
    package.serialize(tempfile.path)
    tempfile.rewind
    tempfile
  end

  def create_standard_test_xlsx
    create_test_xlsx(sheets: {
      "Vegetables" => {
        headers: [ "Variety", "Source", "Year", "Germination", "Notes" ],
        rows: [
          [ "Cherokee Purple Tomato", "Baker Creek", 2023, 0.92, "Great heirloom" ],
          [ "Sugar Snap Pea", "Johnny's Seeds", 2021, nil, "Spring planting" ],
          [ "Red Russian Kale", "Seed Savers", 2020, 0.85, nil ],
          { values: [ "Old Bean", "Unknown", 2015, nil, "used up - empty packet" ], gray: true }
        ]
      },
      "Herbs" => {
        headers: [ "Name", "Supplier", "Date Purchased", "Germ Rate", "Comments" ],
        rows: [
          [ "Genovese Basil", "Baker Creek", "2022", "85%", "Standard basil" ],
          [ "Italian Parsley", "Burpee", "Jan 2023", nil, nil ]
        ]
      },
      "Grains" => {
        headers: [ "Variety", "Source", "Year", "Germination", "Notes" ],
        rows: [
          [ "Turkey Red Wheat", "Sustainable Seed", 2022, 0.90, "Winter wheat" ]
        ]
      },
      "Flowers" => {
        headers: [ "Cultivar", "Purchased From", "Date", "Germ %", "Remarks" ],
        rows: [
          [ "Mammoth Sunflower", "Baker Creek", 2024, 95, "Tall variety" ]
        ]
      },
      "Cover Crops" => {
        headers: [ "Type", "Vendor", "Year Acquired", "Germination Rate", "Info" ],
        rows: [
          [ "Crimson Clover", "Johnny's Seeds", 2023, 0.88, "Fall cover" ]
        ]
      }
    })
  end
end

RSpec.configure do |config|
  config.include XlsxHelper
end
