class TaxonomySidebarComponent < ViewComponent::Base
  def initialize(plant_types:, selected_type: nil, selected_category: nil, selected_subcategory: nil)
    @plant_types = plant_types
    @selected_type = selected_type
    @selected_category = selected_category
    @selected_subcategory = selected_subcategory
  end

  private

  def type_expanded?(plant_type)
    @selected_type == plant_type
  end

  def category_expanded?(plant_category)
    @selected_category == plant_category
  end

  def type_selected?(plant_type)
    @selected_type == plant_type && @selected_category.nil?
  end

  def category_selected?(plant_category)
    @selected_category == plant_category && @selected_subcategory.nil?
  end

  def subcategory_selected?(plant_subcategory)
    @selected_subcategory == plant_subcategory
  end

  def browse_path(plant_type: nil, plant_category: nil, plant_subcategory: nil)
    if plant_subcategory
      helpers.inventory_subcategory_path(plant_type.slug, plant_category.slug, plant_subcategory.slug)
    elsif plant_category
      helpers.inventory_category_path(plant_type.slug, plant_category.slug)
    elsif plant_type
      helpers.inventory_type_path(plant_type.slug)
    else
      helpers.root_path
    end
  end
end
