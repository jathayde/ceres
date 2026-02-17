class PlantTypesController < ApplicationController
  before_action :set_plant_type, only: %i[edit update destroy]

  def index
    @plant_types = PlantType.includes(:plant_categories)
  end

  def new
    @plant_type = PlantType.new
  end

  def create
    @plant_type = PlantType.new(plant_type_params)

    if @plant_type.save
      redirect_to plant_types_path, notice: "Plant type was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @plant_type.update(plant_type_params)
      redirect_to plant_types_path, notice: "Plant type was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @plant_type.deletable?
      @plant_type.destroy
      redirect_to plant_types_path, notice: "Plant type was successfully deleted."
    else
      redirect_to plant_types_path, alert: "Cannot delete plant type with associated categories."
    end
  end

  private

  def set_plant_type
    @plant_type = PlantType.find(params[:id])
  end

  def plant_type_params
    params.require(:plant_type).permit(:name, :description, :position)
  end
end
