# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Plant Types
plant_types = [
  { name: "Vegetable", description: "Edible plants grown for their leaves, roots, stems, or fruits.", position: 1 },
  { name: "Grain", description: "Cereal and pseudo-cereal crops grown for their seeds.", position: 2 },
  { name: "Herb", description: "Plants used for culinary flavoring, medicinal purposes, or fragrance.", position: 3 },
  { name: "Flower", description: "Ornamental and beneficial insect-attracting flowering plants.", position: 4 },
  { name: "Cover Crop", description: "Plants grown to improve soil health, prevent erosion, and fix nitrogen.", position: 5 }
]

plant_types.each do |attrs|
  PlantType.find_or_create_by!(name: attrs[:name]) do |pt|
    pt.description = attrs[:description]
    pt.position = attrs[:position]
  end
end
