class CreatePlants < ActiveRecord::Migration[8.1]
  def change
    create_table :plants do |t|
      t.references :plant_category, null: false, foreign_key: true
      t.references :plant_subcategory, null: true, foreign_key: true
      t.string :name, null: false
      t.string :latin_name
      t.boolean :heirloom, default: false, null: false
      t.integer :days_to_harvest_min
      t.integer :days_to_harvest_max
      t.integer :winter_hardy
      t.integer :life_cycle, null: false
      t.string :planting_seasons, array: true, default: []
      t.integer :expected_viability_years
      t.text :references_urls, array: true, default: []
      t.text :notes

      t.timestamps
    end
  end
end
