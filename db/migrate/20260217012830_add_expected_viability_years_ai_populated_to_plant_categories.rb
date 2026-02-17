class AddExpectedViabilityYearsAiPopulatedToPlantCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :plant_categories, :expected_viability_years_ai_populated, :boolean, default: false, null: false
  end
end
