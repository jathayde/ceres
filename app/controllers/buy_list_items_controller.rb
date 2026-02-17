class BuyListItemsController < ApplicationController
  before_action :set_buy_list_item, only: %i[edit update destroy]

  def index
    @status_filter = params[:status].presence || "pending"
    @buy_list_items = case @status_filter
    when "purchased"
      BuyListItem.purchased
    when "all"
      BuyListItem.all
    else
      BuyListItem.pending
    end
    @buy_list_items = @buy_list_items.includes(:plant_category, :plant_subcategory, :plant)
                                     .order(created_at: :desc)
    @pending_count = BuyListItem.pending.count
    @purchased_count = BuyListItem.purchased.count
  end

  def new
    @buy_list_item = BuyListItem.new
    load_form_options
  end

  def create
    @buy_list_item = BuyListItem.new(buy_list_item_params)

    if @buy_list_item.save
      redirect_to buy_list_items_path, notice: "Item added to buy list."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_options
  end

  def update
    if @buy_list_item.update(buy_list_item_params)
      redirect_to buy_list_items_path, notice: "Buy list item updated."
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @buy_list_item.destroy
    redirect_to buy_list_items_path, notice: "Item removed from buy list."
  end

  def quick_add
    @buy_list_item = BuyListItem.new(buy_list_item_params)

    if @buy_list_item.save
      redirect_back fallback_location: buy_list_items_path, notice: "#{@buy_list_item.target_name} added to buy list."
    else
      redirect_back fallback_location: buy_list_items_path, alert: "Could not add to buy list: #{@buy_list_item.errors.full_messages.join(', ')}"
    end
  end

  def receive
    @item_ids = Array(params[:buy_list_item_ids])
    @buy_list_items = BuyListItem.pending
                                 .where(id: @item_ids)
                                 .includes(:plant_category, :plant_subcategory, :plant)

    if @buy_list_items.empty?
      redirect_to buy_list_items_path, alert: "No pending items were selected."
      return
    end

    @seed_sources = SeedSource.order(:name)
    preload_plants_for_receive
  end

  def plants_for_category
    if params[:plant_category_id].blank? && params[:plant_subcategory_id].blank?
      render json: []
      return
    end

    plants = Plant.order(:name)
    plants = plants.where(plant_category_id: params[:plant_category_id]) if params[:plant_category_id].present?
    plants = plants.where(plant_subcategory_id: params[:plant_subcategory_id]) if params[:plant_subcategory_id].present?
    render json: plants.map { |p| { id: p.id, name: p.name } }
  end

  def fulfill
    if params[:items].blank?
      redirect_to buy_list_items_path, alert: "No items to receive."
      return
    end

    purchases = BuyListItem.fulfill_items(
      params[:items].values,
      seed_source_id: params[:shared_seed_source_id],
      year_purchased: params[:shared_year_purchased]
    )

    if purchases.any?
      redirect_to buy_list_items_path, notice: "#{purchases.size} #{"purchase".pluralize(purchases.size)} created successfully."
    else
      redirect_to buy_list_items_path, alert: "No purchases were created."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to buy_list_items_path, alert: "Error receiving items: #{e.message}"
  end

  private

  def set_buy_list_item
    @buy_list_item = BuyListItem.find(params[:id])
  end

  def load_form_options
    @plant_types = PlantType.order(:name)
    @plant_categories = PlantCategory.includes(:plant_type).order(:name)
    @plant_subcategories = PlantSubcategory.includes(:plant_category).order(:name)
    @plants = Plant.includes(:plant_category).order(:name)
  end

  def preload_plants_for_receive
    category_ids = @buy_list_items.select(&:plant_category_id?).map(&:plant_category_id)
    subcategory_ids = @buy_list_items.select(&:plant_subcategory_id?).map(&:plant_subcategory_id)

    @plants_by_scope = {}

    scope = Plant.none
    scope = scope.or(Plant.where(plant_category_id: category_ids)) if category_ids.any?
    scope = scope.or(Plant.where(plant_subcategory_id: subcategory_ids)) if subcategory_ids.any?

    scope.order(:name).each do |plant|
      key = plant.plant_subcategory_id ? [ :subcategory, plant.plant_subcategory_id ] : [ :category, plant.plant_category_id ]
      (@plants_by_scope[key] ||= []) << plant
    end
  end

  def buy_list_item_params
    params.require(:buy_list_item).permit(:plant_category_id, :plant_subcategory_id, :plant_id, :notes)
  end
end
