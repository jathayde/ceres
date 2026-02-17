class SeedPurchasesController < ApplicationController
  before_action :set_seed_purchase, only: %i[edit update destroy]

  def index
    @seed_purchases = SeedPurchase.includes(:plant, :seed_source)
                                  .order("plants.name", year_purchased: :desc)
                                  .references(:plant)
  end

  def new
    @seed_purchase = SeedPurchase.new
    @seed_purchase.plant_id = params[:plant_id] if params[:plant_id].present?
    load_form_options
  end

  def create
    @seed_purchase = SeedPurchase.new(seed_purchase_params)

    if @seed_purchase.save
      redirect_to seed_purchases_path, notice: "Seed purchase was successfully created."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_options
  end

  def update
    if @seed_purchase.update(seed_purchase_params)
      redirect_to seed_purchases_path, notice: "Seed purchase was successfully updated."
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @seed_purchase.destroy
    redirect_to seed_purchases_path, notice: "Seed purchase was successfully deleted."
  end

  def plants_search
    plants = Plant.includes(:plant_category)
                  .where("plants.name ILIKE ?", "%#{params[:q]}%")
                  .order(:name)
                  .limit(20)
    render json: plants.map { |p| { id: p.id, name: "#{p.name} (#{p.plant_category.name})" } }
  end

  private

  def set_seed_purchase
    @seed_purchase = SeedPurchase.find(params[:id])
  end

  def load_form_options
    @plants = Plant.includes(:plant_category).order("plant_categories.name", :name).references(:plant_category)
    @seed_sources = SeedSource.all
  end

  def seed_purchase_params
    params.require(:seed_purchase).permit(
      :plant_id, :seed_source_id, :year_purchased, :lot_number,
      :germination_rate, :weight_oz, :seed_count, :packet_count,
      :cost_cents, :reorder_url, :notes
    )
  end
end
