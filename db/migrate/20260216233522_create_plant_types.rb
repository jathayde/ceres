class CreatePlantTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :plant_types do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position

      t.timestamps
    end

    add_index :plant_types, :name, unique: true
  end
end
