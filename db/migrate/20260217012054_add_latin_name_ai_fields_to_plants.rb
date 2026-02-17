class AddLatinNameAiFieldsToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :latin_name_ai_populated, :boolean, default: false, null: false
    add_column :plant_categories, :latin_genus_ai_populated, :boolean, default: false, null: false
    add_column :plant_categories, :latin_species_ai_populated, :boolean, default: false, null: false
  end
end
