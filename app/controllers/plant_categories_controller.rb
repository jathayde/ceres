class PlantCategoriesController < ApplicationController
  before_action :set_plant_type
  before_action :set_plant_category, only: %i[edit update destroy research_viability]

  def index
    @plant_categories = @plant_type.plant_categories.includes(:plants, :plant_subcategories)
  end

  def new
    @plant_category = @plant_type.plant_categories.build
  end

  def create
    @plant_category = @plant_type.plant_categories.build(plant_category_params)

    if @plant_category.save
      redirect_to plant_type_plant_categories_path(@plant_type), notice: "Plant category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @plant_category.update(plant_category_params)
      redirect_to plant_type_plant_categories_path(@plant_type), notice: "Plant category was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def research_viability
    ViabilityDataEnrichmentJob.perform_later(@plant_category.id)
    redirect_to plant_type_plant_categories_path(@plant_type), notice: "Viability research started for #{@plant_category.name}. Results will appear shortly."
  end

  def destroy
    if @plant_category.deletable?
      @plant_category.destroy
      redirect_to plant_type_plant_categories_path(@plant_type), notice: "Plant category was successfully deleted."
    else
      redirect_to plant_type_plant_categories_path(@plant_type), alert: "Cannot delete category with associated plants or subcategories."
    end
  end

  private

  def set_plant_type
    @plant_type = PlantType.find(params[:plant_type_id])
  end

  def set_plant_category
    @plant_category = @plant_type.plant_categories.find(params[:id])
  end

  def plant_category_params
    params.require(:plant_category).permit(:name, :latin_genus, :latin_species, :expected_viability_years, :description, :position)
  end
end
