class PlantsController < ApplicationController
  before_action :set_plant, only: %i[show edit update destroy research_growing_guide]

  def index
    @plants = Plant.includes(:plant_category, :plant_subcategory, :seed_purchases)
                   .order("plant_categories.name", :name)
                   .references(:plant_category)
  end

  def show
    redirect_to helpers.inventory_path_for_plant(@plant), status: :moved_permanently
  end

  def new
    @plant = Plant.new
    load_form_options
  end

  def create
    @plant = Plant.new(plant_params)

    if @plant.save
      redirect_to plants_path, notice: "Plant was successfully created."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_options
  end

  def update
    if @plant.update(plant_params)
      redirect_to plants_path, notice: "Plant was successfully updated."
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @plant.deletable?
      @plant.destroy
      redirect_to plants_path, notice: "Plant was successfully deleted."
    else
      redirect_to plants_path, alert: "Cannot delete plant with associated seed purchases."
    end
  end

  def research_growing_guide
    guideable = @plant.plant_subcategory || @plant.plant_category
    GrowingGuideResearchJob.perform_later(guideable.id, guideable.class.name)
    redirect_to plant_path(@plant, back_to: params[:back_to]),
      notice: "Growing guide research started. Results will appear shortly."
  end

  def categories_for_type
    categories = PlantCategory.where(plant_type_id: params[:plant_type_id])
    render json: categories.map { |c| { id: c.id, name: c.name } }
  end

  def subcategories_for_category
    subcategories = PlantSubcategory.where(plant_category_id: params[:plant_category_id])
    render json: subcategories.map { |s| { id: s.id, name: s.name } }
  end

  private

  def set_plant
    @plant = Plant.find_by(slug: params[:id]) || Plant.find(params[:id])
  end

  def load_form_options
    @plant_types = PlantType.all
    @plant_categories = if @plant.plant_category_id.present?
      PlantCategory.where(plant_type_id: @plant.plant_category&.plant_type_id)
    else
      PlantCategory.none
    end
    @plant_subcategories = if @plant.plant_category_id.present?
      PlantSubcategory.where(plant_category_id: @plant.plant_category_id)
    else
      PlantSubcategory.none
    end
  end

  def plant_params
    params.require(:plant).permit(
      :plant_category_id, :plant_subcategory_id, :name, :latin_name,
      :heirloom, :days_to_harvest_min, :days_to_harvest_max,
      :winter_hardy, :life_cycle, :expected_viability_years, :notes,
      planting_seasons: [], references_urls: []
    )
  end
end
