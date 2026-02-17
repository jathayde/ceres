class InventoryBreadcrumbComponent < ViewComponent::Base
  def initialize(plant_type: nil, plant_category: nil, plant_subcategory: nil)
    @plant_type = plant_type
    @plant_category = plant_category
    @plant_subcategory = plant_subcategory
  end

  def render?
    @plant_type.present?
  end

  def crumbs
    items = []
    items << { label: "All Plants", path: helpers.root_path }

    if @plant_type
      items << { label: @plant_type.name, path: helpers.inventory_browse_path(plant_type_id: @plant_type.id) }
    end

    if @plant_category
      items << { label: @plant_category.name, path: helpers.inventory_browse_path(plant_type_id: @plant_type.id, plant_category_id: @plant_category.id) }
    end

    if @plant_subcategory
      items << { label: @plant_subcategory.name, path: nil }
    end

    items
  end
end
