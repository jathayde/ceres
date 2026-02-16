class CreatePlantCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :plant_categories do |t|
      t.references :plant_type, null: false, foreign_key: true
      t.string :name, null: false
      t.string :latin_genus
      t.string :latin_species
      t.integer :expected_viability_years
      t.text :description
      t.integer :position

      t.timestamps
    end

    add_index :plant_categories, [ :plant_type_id, :name ], unique: true
  end
end
