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

  def merge
    @source_ids = Array(params[:source_ids]).map(&:to_i)

    if @source_ids.size < 2
      redirect_to seed_sources_path, alert: "Select at least two seed sources to merge."
      return
    end

    @sources = SeedSource.where(id: @source_ids).includes(:seed_purchases)
  end

  def execute_merge
    primary_id = params[:primary_id].to_i
    all_ids = Array(params[:merge_ids]).map(&:to_i)
    other_ids = all_ids - [ primary_id ]

    primary = SeedSource.find(primary_id)
    others = SeedSource.where(id: other_ids)

    if others.empty?
      redirect_to seed_sources_path, alert: "No sources selected to merge."
      return
    end

    primary.merge_with!(others)
    redirect_to seed_sources_path, notice: "Seed sources merged successfully into #{primary.name}."
  end

  private

  def set_seed_source
    @seed_source = SeedSource.find(params[:id])
  end

  def seed_source_params
    params.require(:seed_source).permit(:name, :url, :notes)
  end
end
