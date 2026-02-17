class MoveGrowingGuideToCategory < ActiveRecord::Migration[8.1]
  def up
    add_reference :growing_guides, :plant_category, null: true, foreign_key: true
    add_reference :growing_guides, :plant_subcategory, null: true, foreign_key: true

    # Migrate existing data: copy category/subcategory from the associated plant
    execute <<~SQL
      UPDATE growing_guides
      SET plant_category_id = plants.plant_category_id,
          plant_subcategory_id = plants.plant_subcategory_id
      FROM plants
      WHERE growing_guides.plant_id = plants.id
    SQL

    # For guides where the plant had a subcategory, clear the category
    # (guide attaches to the most specific level)
    execute <<~SQL
      UPDATE growing_guides
      SET plant_category_id = NULL
      WHERE plant_subcategory_id IS NOT NULL
    SQL

    # For guides where multiple plants in the same category/subcategory
    # had guides, keep only the most recently updated one
    execute <<~SQL
      DELETE FROM growing_guides
      WHERE id NOT IN (
        SELECT DISTINCT ON (plant_category_id) id
        FROM growing_guides
        WHERE plant_category_id IS NOT NULL
        ORDER BY plant_category_id, updated_at DESC
      )
      AND plant_category_id IS NOT NULL
    SQL

    execute <<~SQL
      DELETE FROM growing_guides
      WHERE id NOT IN (
        SELECT DISTINCT ON (plant_subcategory_id) id
        FROM growing_guides
        WHERE plant_subcategory_id IS NOT NULL
        ORDER BY plant_subcategory_id, updated_at DESC
      )
      AND plant_subcategory_id IS NOT NULL
    SQL

    remove_reference :growing_guides, :plant, null: false, foreign_key: true

    add_index :growing_guides, :plant_category_id, unique: true, where: "plant_category_id IS NOT NULL",
              name: "index_growing_guides_on_plant_category_id_unique"
    add_index :growing_guides, :plant_subcategory_id, unique: true, where: "plant_subcategory_id IS NOT NULL",
              name: "index_growing_guides_on_plant_subcategory_id_unique"

    # Exactly one of category or subcategory must be set
    execute <<~SQL
      ALTER TABLE growing_guides
      ADD CONSTRAINT chk_growing_guide_belongs_to_one
      CHECK (
        (plant_category_id IS NOT NULL AND plant_subcategory_id IS NULL)
        OR
        (plant_category_id IS NULL AND plant_subcategory_id IS NOT NULL)
      )
    SQL
  end

  def down
    execute "ALTER TABLE growing_guides DROP CONSTRAINT chk_growing_guide_belongs_to_one"

    remove_index :growing_guides, name: "index_growing_guides_on_plant_category_id_unique"
    remove_index :growing_guides, name: "index_growing_guides_on_plant_subcategory_id_unique"

    add_reference :growing_guides, :plant, null: true, foreign_key: true

    # Best-effort reverse: assign guide to the first plant in the category/subcategory
    execute <<~SQL
      UPDATE growing_guides
      SET plant_id = (
        SELECT plants.id FROM plants
        WHERE plants.plant_subcategory_id = growing_guides.plant_subcategory_id
        LIMIT 1
      )
      WHERE plant_subcategory_id IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE growing_guides
      SET plant_id = (
        SELECT plants.id FROM plants
        WHERE plants.plant_category_id = growing_guides.plant_category_id
        AND plants.plant_subcategory_id IS NULL
        LIMIT 1
      )
      WHERE plant_category_id IS NOT NULL AND plant_id IS NULL
    SQL

    # Delete orphaned guides that couldn't find a plant
    execute "DELETE FROM growing_guides WHERE plant_id IS NULL"

    change_column_null :growing_guides, :plant_id, false
    add_index :growing_guides, :plant_id, unique: true

    remove_reference :growing_guides, :plant_category
    remove_reference :growing_guides, :plant_subcategory
  end
end
