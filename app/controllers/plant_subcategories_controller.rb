class PlantSubcategoriesController < ApplicationController
  before_action :set_plant_type
  before_action :set_plant_category
  before_action :set_plant_subcategory, only: %i[edit update destroy]

  def index
    @plant_subcategories = @plant_category.plant_subcategories.includes(:plants)
  end

  def new
    @plant_subcategory = @plant_category.plant_subcategories.build
  end

  def create
    @plant_subcategory = @plant_category.plant_subcategories.build(plant_subcategory_params)

    if @plant_subcategory.save
      redirect_to plant_type_plant_category_plant_subcategories_path(@plant_type, @plant_category),
        notice: "Plant subcategory was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @plant_subcategory.update(plant_subcategory_params)
      redirect_to plant_type_plant_category_plant_subcategories_path(@plant_type, @plant_category),
        notice: "Plant subcategory was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @plant_subcategory.deletable?
      @plant_subcategory.destroy
      redirect_to plant_type_plant_category_plant_subcategories_path(@plant_type, @plant_category),
        notice: "Plant subcategory was successfully deleted."
    else
      redirect_to plant_type_plant_category_plant_subcategories_path(@plant_type, @plant_category),
        alert: "Cannot delete subcategory with associated plants."
    end
  end

  private

  def set_plant_type
    @plant_type = PlantType.find_by!(slug: params[:plant_type_id])
  end

  def set_plant_category
    @plant_category = @plant_type.plant_categories.find_by!(slug: params[:plant_category_id])
  end

  def set_plant_subcategory
    @plant_subcategory = @plant_category.plant_subcategories.find_by!(slug: params[:id])
  end

  def plant_subcategory_params
    params.require(:plant_subcategory).permit(:name, :description, :position)
  end
end
