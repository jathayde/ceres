class InventoryBreadcrumbComponent < ViewComponent::Base
  def initialize(plant_type: nil, plant_category: nil, plant_subcategory: nil, plant: nil)
    @plant_type = plant_type
    @plant_category = plant_category
    @plant_subcategory = plant_subcategory
    @plant = plant
  end

  def render?
    @plant_type.present?
  end

  def crumbs
    items = []
    items << { label: "All Plants", path: helpers.root_path }

    if @plant_type
      items << { label: @plant_type.name, path: helpers.inventory_type_path(@plant_type.slug) }
    end

    if @plant_category
      items << { label: @plant_category.name, path: helpers.inventory_category_path(@plant_type.slug, @plant_category.slug) }
    end

    if @plant_subcategory
      items << { label: @plant_subcategory.name, path: helpers.inventory_subcategory_path(@plant_type.slug, @plant_category.slug, @plant_subcategory.slug) }
    end

    if @plant
      items << { label: @plant.name, path: nil }
    end

    items
  end
end
