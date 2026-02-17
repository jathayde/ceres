module InventoryUrlHelper
  def inventory_path_for_type(type)
    inventory_type_path(type.slug)
  end

  def inventory_path_for_category(category)
    inventory_category_path(category.plant_type.slug, category.slug)
  end

  def inventory_path_for_subcategory(subcategory)
    category = subcategory.plant_category
    inventory_subcategory_path(category.plant_type.slug, category.slug, subcategory.slug)
  end

  def inventory_path_for_plant(plant)
    category = plant.plant_category
    type_slug = category.plant_type.slug

    if plant.plant_subcategory.present?
      inventory_subcategory_variety_path(type_slug, category.slug, plant.plant_subcategory.slug, plant.slug)
    else
      inventory_variety_path(type_slug, category.slug, plant.slug)
    end
  end
end
