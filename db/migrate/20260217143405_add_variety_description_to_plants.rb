class AddVarietyDescriptionToPlants < ActiveRecord::Migration[8.1]
  def up
    add_column :plants, :variety_description, :text
    add_column :plants, :variety_description_ai_populated, :boolean, default: false, null: false

    # Delete all existing growing guides — they contain variety-specific content
    # that was incorrectly migrated to category-level guides
    execute "DELETE FROM growing_guides"
  end

  def down
    remove_column :plants, :variety_description_ai_populated
    remove_column :plants, :variety_description
  end
end
