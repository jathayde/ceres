class CreatePlantSubcategories < ActiveRecord::Migration[8.1]
  def change
    create_table :plant_subcategories do |t|
      t.references :plant_category, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :position

      t.timestamps
    end

    add_index :plant_subcategories, [ :plant_category_id, :name ], unique: true
  end
end
