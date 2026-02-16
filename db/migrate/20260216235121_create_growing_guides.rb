class CreateGrowingGuides < ActiveRecord::Migration[8.1]
  def change
    create_table :growing_guides do |t|
      t.references :plant, null: false, foreign_key: true, index: { unique: true }
      t.text :overview
      t.text :soil_requirements
      t.integer :sun_exposure
      t.integer :water_needs
      t.integer :spacing_inches
      t.integer :row_spacing_inches
      t.decimal :planting_depth_inches
      t.integer :germination_temp_min_f
      t.integer :germination_temp_max_f
      t.integer :germination_days_min
      t.integer :germination_days_max
      t.text :growing_tips
      t.text :harvest_notes
      t.text :seed_saving_notes
      t.boolean :ai_generated, default: false, null: false
      t.datetime :ai_generated_at

      t.timestamps
    end
  end
end
