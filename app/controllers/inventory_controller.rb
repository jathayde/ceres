class InventoryController < ApplicationController
  def index
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    load_filters
    load_plants
  end

  def type_show
    @plant_type = PlantType.find_by!(slug: params[:type_slug])
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    @categories = @plant_type.plant_categories.includes(:plants, :plant_subcategories)
    load_filters
    load_plants
  end

  def category_show
    @plant_type = PlantType.find_by!(slug: params[:type_slug])
    @plant_category = @plant_type.plant_categories.find_by!(slug: params[:category_slug])
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    @guideable = @plant_category
    @growing_guide = @plant_category.growing_guide
    @subcategories = @plant_category.plant_subcategories
    load_filters
    load_plants
  end

  def subcategory_show
    @plant_type = PlantType.find_by!(slug: params[:type_slug])
    @plant_category = @plant_type.plant_categories.find_by!(slug: params[:category_slug])
    @plant_subcategory = @plant_category.plant_subcategories.find_by!(slug: params[:subcategory_slug])
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @search_query = params[:q].to_s.strip
    @guideable = @plant_subcategory
    @growing_guide = @plant_subcategory.growing_guide
    load_filters
    load_plants
  end

  def variety_show
    @plant_type = PlantType.find_by!(slug: params[:type_slug])
    @plant_category = @plant_type.plant_categories.find_by!(slug: params[:category_slug])
    @plant = @plant_category.plants.where(plant_subcategory_id: nil).find_by!(slug: params[:plant_slug])
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @seed_purchases = @plant.seed_purchases.includes(:seed_source).order(year_purchased: :desc)
    @growing_guide = @plant.growing_guide
  end

  def subcategory_variety_show
    @plant_type = PlantType.find_by!(slug: params[:type_slug])
    @plant_category = @plant_type.plant_categories.find_by!(slug: params[:category_slug])
    @plant_subcategory = @plant_category.plant_subcategories.find_by!(slug: params[:subcategory_slug])
    @plant = @plant_subcategory.plants.find_by!(slug: params[:plant_slug])
    @plant_types = PlantType.includes(plant_categories: :plant_subcategories).all
    @seed_purchases = @plant.seed_purchases.includes(:seed_source).order(year_purchased: :desc)
    @growing_guide = @plant.growing_guide
    render :variety_show
  end

  GUIDEABLE_TYPES = { "PlantCategory" => PlantCategory, "PlantSubcategory" => PlantSubcategory }.freeze

  def research_growing_guide
    klass = GUIDEABLE_TYPES[params[:guideable_type]] || raise(ActiveRecord::RecordNotFound)
    guideable = klass.find(params[:guideable_id])
    GrowingGuideResearchJob.perform_later(guideable.id, guideable.class.name)
    redirect_back fallback_location: root_path,
      notice: "Growing guide research started. Results will appear shortly."
  end

  def browse_redirect
    if params[:plant_subcategory_id].present?
      sub = PlantSubcategory.find(params[:plant_subcategory_id])
      cat = sub.plant_category
      redirect_to inventory_subcategory_path(cat.plant_type.slug, cat.slug, sub.slug), status: :moved_permanently
    elsif params[:plant_category_id].present?
      cat = PlantCategory.find(params[:plant_category_id])
      redirect_to inventory_category_path(cat.plant_type.slug, cat.slug), status: :moved_permanently
    elsif params[:plant_type_id].present?
      type = PlantType.find(params[:plant_type_id])
      redirect_to inventory_type_path(type.slug), status: :moved_permanently
    else
      redirect_to root_path, status: :moved_permanently
    end
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
