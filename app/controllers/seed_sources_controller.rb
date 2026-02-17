class SeedSourcesController < ApplicationController
  before_action :set_seed_source, only: %i[edit update destroy]

  def index
    @seed_sources = SeedSource.includes(:seed_purchases)
  end

  def new
    @seed_source = SeedSource.new
  end

  def create
    @seed_source = SeedSource.new(seed_source_params)

    if @seed_source.save
      redirect_to seed_sources_path, notice: "Seed source was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @seed_source.update(seed_source_params)
      redirect_to seed_sources_path, notice: "Seed source was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @seed_source.deletable?
      @seed_source.destroy
      redirect_to seed_sources_path, notice: "Seed source was successfully deleted."
    else
      redirect_to seed_sources_path, alert: "Cannot delete seed source with associated purchases."
    end
  end

  def inline_create
    @seed_source = SeedSource.new(seed_source_params)

    if @seed_source.save
      render json: { id: @seed_source.id, name: @seed_source.name }, status: :created
    else
      render json: { errors: @seed_source.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_seed_source
    @seed_source = SeedSource.find(params[:id])
  end

  def seed_source_params
    params.require(:seed_source).permit(:name, :url, :notes)
  end
end
