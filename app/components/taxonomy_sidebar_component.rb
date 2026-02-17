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
    params = {}
    params[:plant_type_id] = plant_type.id if plant_type
    params[:plant_category_id] = plant_category.id if plant_category
    params[:plant_subcategory_id] = plant_subcategory.id if plant_subcategory
    helpers.inventory_browse_path(params)
  end
end
