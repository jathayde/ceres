class SeedPurchasesController < ApplicationController
  before_action :set_seed_purchase, only: %i[edit update destroy mark_as_used_up mark_as_active]

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

  def mark_as_used_up
    @seed_purchase.update!(used_up: true, used_up_at: Date.current)
    redirect_to seed_purchases_path, notice: "#{@seed_purchase.plant.name} (#{@seed_purchase.year_purchased}) marked as used up."
  end

  def mark_as_active
    @seed_purchase.update!(used_up: false, used_up_at: nil)
    redirect_to seed_purchases_path, notice: "#{@seed_purchase.plant.name} (#{@seed_purchase.year_purchased}) marked as active."
  end

  def bulk_mark_used_up
    ids = params[:seed_purchase_ids]
    if ids.present?
      count = SeedPurchase.where(id: ids, used_up: false).update_all(used_up: true, used_up_at: Date.current)
      redirect_to seed_purchases_path, notice: "#{count} #{"purchase".pluralize(count)} marked as used up."
    else
      redirect_to seed_purchases_path, alert: "No purchases were selected."
    end
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
