class InventoryController < ApplicationController
  def index
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    load_plants
  end

  def browse
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    load_browse_context
    load_plants
  end

  private

  def load_browse_context
    if params[:plant_subcategory_id].present?
      @plant_subcategory = PlantSubcategory.find(params[:plant_subcategory_id])
      @plant_category = @plant_subcategory.plant_category
      @plant_type = @plant_category.plant_type
    elsif params[:plant_category_id].present?
      @plant_category = PlantCategory.find(params[:plant_category_id])
      @plant_type = @plant_category.plant_type
    elsif params[:plant_type_id].present?
      @plant_type = PlantType.find(params[:plant_type_id])
    end
  end

  def load_plants
    if @search_query.present?
      scope = Plant.search(@search_query)
        .includes(:plant_category, :plant_subcategory, seed_purchases: :seed_source)
    else
      scope = Plant.includes(:plant_category, :plant_subcategory, seed_purchases: :seed_source)
    end

    if @plant_subcategory
      scope = scope.where(plant_subcategory_id: @plant_subcategory.id)
    elsif @plant_category
      scope = scope.where(plant_category_id: @plant_category.id)
    elsif @plant_type
      scope = scope.where(plant_category_id: @plant_type.plant_categories.select(:id))
    end

    if @search_query.present?
      @plants = scope.references(:plant_category)
    else
      @plants = scope.order("plant_categories.name", :name).references(:plant_category)
    end
  end
end
