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

# Plant Categories with expected viability years
# Keyed by PlantType name for proper association
plant_categories = {
  "Vegetable" => [
    { name: "Onion", expected_viability_years: 2, latin_genus: "Allium", latin_species: "cepa", position: 1 },
    { name: "Leek", expected_viability_years: 2, latin_genus: "Allium", latin_species: "ampeloprasum", position: 2 },
    { name: "Chive", expected_viability_years: 2, latin_genus: "Allium", latin_species: "schoenoprasum", position: 3 },
    { name: "Parsnip", expected_viability_years: 2, latin_genus: "Pastinaca", latin_species: "sativa", position: 4 },
    { name: "Salsify", expected_viability_years: 2, latin_genus: "Tragopogon", latin_species: "porrifolius", position: 5 },
    { name: "Pepper", expected_viability_years: 3, latin_genus: "Capsicum", position: 6 },
    { name: "Corn", expected_viability_years: 3, latin_genus: "Zea", latin_species: "mays", position: 7 },
    { name: "Bean", expected_viability_years: 4, latin_genus: "Phaseolus", position: 8 },
    { name: "Pea", expected_viability_years: 4, latin_genus: "Pisum", latin_species: "sativum", position: 9 },
    { name: "Carrot", expected_viability_years: 4, latin_genus: "Daucus", latin_species: "carota", position: 10 },
    { name: "Celery", expected_viability_years: 4, latin_genus: "Apium", latin_species: "graveolens", position: 11 },
    { name: "Lettuce", expected_viability_years: 5, latin_genus: "Lactuca", latin_species: "sativa", position: 12 },
    { name: "Endive", expected_viability_years: 5, latin_genus: "Cichorium", latin_species: "endivia", position: 13 },
    { name: "Brassica", expected_viability_years: 5, latin_genus: "Brassica", position: 14 },
    { name: "Beet", expected_viability_years: 5, latin_genus: "Beta", latin_species: "vulgaris", position: 15 },
    { name: "Chard", expected_viability_years: 5, latin_genus: "Beta", latin_species: "vulgaris", position: 16 },
    { name: "Tomato", expected_viability_years: 5, latin_genus: "Solanum", latin_species: "lycopersicum", position: 17 },
    { name: "Eggplant", expected_viability_years: 5, latin_genus: "Solanum", latin_species: "melongena", position: 18 },
    { name: "Cucurbit", expected_viability_years: 6, latin_genus: "Cucurbita", position: 19 },
    { name: "Radish", expected_viability_years: 5, latin_genus: "Raphanus", latin_species: "sativus", position: 20 },
    { name: "Turnip", expected_viability_years: 5, latin_genus: "Brassica", latin_species: "rapa", position: 21 }
  ],
  "Grain" => [
    { name: "Wheat", expected_viability_years: 4, latin_genus: "Triticum", position: 1 },
    { name: "Oat", expected_viability_years: 3, latin_genus: "Avena", latin_species: "sativa", position: 2 },
    { name: "Rye", expected_viability_years: 3, latin_genus: "Secale", latin_species: "cereale", position: 3 },
    { name: "Barley", expected_viability_years: 3, latin_genus: "Hordeum", latin_species: "vulgare", position: 4 }
  ],
  "Herb" => [
    { name: "Basil", expected_viability_years: 5, latin_genus: "Ocimum", latin_species: "basilicum", position: 1 },
    { name: "Cilantro", expected_viability_years: 3, latin_genus: "Coriandrum", latin_species: "sativum", position: 2 },
    { name: "Dill", expected_viability_years: 5, latin_genus: "Anethum", latin_species: "graveolens", position: 3 },
    { name: "Parsley", expected_viability_years: 3, latin_genus: "Petroselinum", latin_species: "crispum", position: 4 }
  ],
  "Flower" => [
    { name: "Sunflower", expected_viability_years: 5, latin_genus: "Helianthus", latin_species: "annuus", position: 1 },
    { name: "Zinnia", expected_viability_years: 5, latin_genus: "Zinnia", position: 2 },
    { name: "Marigold", expected_viability_years: 3, latin_genus: "Tagetes", position: 3 },
    { name: "Cosmos", expected_viability_years: 4, latin_genus: "Cosmos", position: 4 }
  ],
  "Cover Crop" => [
    { name: "Clover", expected_viability_years: 3, latin_genus: "Trifolium", position: 1 },
    { name: "Vetch", expected_viability_years: 3, latin_genus: "Vicia", position: 2 },
    { name: "Buckwheat", expected_viability_years: 3, latin_genus: "Fagopyrum", latin_species: "esculentum", position: 3 }
  ]
}

plant_categories.each do |plant_type_name, categories|
  plant_type = PlantType.find_by!(name: plant_type_name)

  categories.each do |attrs|
    PlantCategory.find_or_create_by!(plant_type: plant_type, name: attrs[:name]) do |pc|
      pc.expected_viability_years = attrs[:expected_viability_years]
      pc.latin_genus = attrs[:latin_genus]
      pc.latin_species = attrs[:latin_species]
      pc.position = attrs[:position]
    end
  end
end
