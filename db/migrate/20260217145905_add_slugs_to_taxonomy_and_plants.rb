class AddSlugsToTaxonomyAndPlants < ActiveRecord::Migration[8.1]
  def up
    add_column :plant_types, :slug, :string
    add_column :plant_categories, :slug, :string
    add_column :plant_subcategories, :slug, :string
    add_column :plants, :slug, :string

    # Populate slugs from names using parameterize-equivalent SQL
    execute <<~SQL
      UPDATE plant_types SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(name), '[^a-zA-Z0-9\\-\\s]', '', 'g'), '\\s+', '-', 'g'));
    SQL
    execute <<~SQL
      UPDATE plant_categories SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(name), '[^a-zA-Z0-9\\-\\s]', '', 'g'), '\\s+', '-', 'g'));
    SQL
    execute <<~SQL
      UPDATE plant_subcategories SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(name), '[^a-zA-Z0-9\\-\\s]', '', 'g'), '\\s+', '-', 'g'));
    SQL
    execute <<~SQL
      UPDATE plants SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(name), '[^a-zA-Z0-9\\-\\s]', '', 'g'), '\\s+', '-', 'g'));
    SQL

    # Handle plant slug collisions within the same category+subcategory scope
    execute <<~SQL
      WITH duplicates AS (
        SELECT id, slug, plant_category_id, plant_subcategory_id,
               ROW_NUMBER() OVER (
                 PARTITION BY plant_category_id, COALESCE(plant_subcategory_id, 0), slug
                 ORDER BY id
               ) AS rn
        FROM plants
      )
      UPDATE plants SET slug = plants.slug || '-' || duplicates.rn
      FROM duplicates
      WHERE plants.id = duplicates.id AND duplicates.rn > 1;
    SQL

    change_column_null :plant_types, :slug, false
    change_column_null :plant_categories, :slug, false
    change_column_null :plant_subcategories, :slug, false
    change_column_null :plants, :slug, false

    add_index :plant_types, :slug, unique: true
    add_index :plant_categories, [ :plant_type_id, :slug ], unique: true
    add_index :plant_subcategories, [ :plant_category_id, :slug ], unique: true
    add_index :plants, [ :plant_category_id, :plant_subcategory_id, :slug ], unique: true,
              name: "index_plants_on_category_subcategory_slug"
  end

  def down
    remove_index :plants, name: "index_plants_on_category_subcategory_slug"
    remove_index :plant_subcategories, [ :plant_category_id, :slug ]
    remove_index :plant_categories, [ :plant_type_id, :slug ]
    remove_index :plant_types, :slug

    remove_column :plants, :slug
    remove_column :plant_subcategories, :slug
    remove_column :plant_categories, :slug
    remove_column :plant_types, :slug
  end
end
