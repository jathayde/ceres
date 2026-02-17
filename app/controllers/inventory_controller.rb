class InventoryController < ApplicationController
  def index
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    load_filters
    load_plants
  end

  def browse
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    load_browse_context
    load_filters
    load_plants
  end

  def bulk_mark_used_up
    ids = params[:plant_ids]
    if ids.present?
      count = SeedPurchase.where(plant_id: ids, used_up: false).update_all(used_up: true, used_up_at: Date.current)
      redirect_to root_path, notice: "#{count} #{"purchase".pluralize(count)} marked as used up."
    else
      redirect_to root_path, alert: "No plants were selected."
    end
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

  def load_filters
    @viability_filter = params[:viability].presence
    @heirloom_filter = params[:heirloom] == "1"
    @seed_source_filter = params[:seed_source_id].presence
    @seed_sources = SeedSource.all
    @filters_active = @viability_filter.present? || @heirloom_filter || @seed_source_filter.present?
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

    scope = scope.with_viability_status(@viability_filter) if @viability_filter.present?
    scope = scope.heirloom if @heirloom_filter
    scope = scope.with_seed_source(@seed_source_filter) if @seed_source_filter.present?

    if @search_query.present?
      @plants = scope.references(:plant_category)
    else
      @plants = scope.order("plant_categories.name", :name).references(:plant_category)
    end
  end
end
