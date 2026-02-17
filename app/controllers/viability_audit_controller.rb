class ViabilityAuditController < ApplicationController
  def index
    load_filters
    load_purchases

    @summary = {
      viable: @all_active_purchases.count { |p| p.viability_status == :viable },
      test: @all_active_purchases.count { |p| p.viability_status == :test },
      expired: @all_active_purchases.count { |p| p.viability_status == :expired }
    }
  end

  def mark_as_used_up
    purchase = SeedPurchase.find(params[:id])
    purchase.update!(used_up: true, used_up_at: Date.current)
    redirect_to viability_audit_path(filter_params), notice: "#{purchase.plant.name} (#{purchase.year_purchased}) marked as used up."
  end

  def bulk_mark_used_up
    ids = params[:seed_purchase_ids]
    if ids.present?
      count = SeedPurchase.where(id: ids, used_up: false).update_all(used_up: true, used_up_at: Date.current)
      redirect_to viability_audit_path(filter_params), notice: "#{count} #{"purchase".pluralize(count)} marked as used up."
    else
      redirect_to viability_audit_path(filter_params), alert: "No purchases were selected."
    end
  end

  private

  def load_filters
    @viability_filter = params[:viability].presence
    @plant_type_filter = params[:plant_type_id].presence
    @plant_category_filter = params[:plant_category_id].presence
    @seed_source_filter = params[:seed_source_id].presence
    @year_from_filter = params[:year_from].presence
    @year_to_filter = params[:year_to].presence
    @sort = params[:sort].presence || "urgency"

    @plant_types = PlantType.all
    @plant_categories = if @plant_type_filter
      PlantCategory.where(plant_type_id: @plant_type_filter)
    else
      PlantCategory.all
    end
    @seed_sources = SeedSource.all

    @filters_active = [ @viability_filter, @plant_type_filter, @plant_category_filter,
                         @seed_source_filter, @year_from_filter, @year_to_filter ].any?(&:present?)
  end

  def load_purchases
    scope = SeedPurchase.where(used_up: false)
                        .includes(plant: :plant_category)
                        .includes(:seed_source)

    @all_active_purchases = scope.to_a

    scope = apply_filters(scope)
    @purchases = apply_sort(scope).to_a
  end

  def apply_filters(scope)
    if @viability_filter.present?
      purchase_ids = scope.to_a.select { |p| p.viability_status.to_s == @viability_filter }.map(&:id)
      scope = scope.where(id: purchase_ids)
    end

    if @plant_category_filter.present?
      scope = scope.joins(:plant).where(plants: { plant_category_id: @plant_category_filter })
    elsif @plant_type_filter.present?
      category_ids = PlantCategory.where(plant_type_id: @plant_type_filter).pluck(:id)
      scope = scope.joins(:plant).where(plants: { plant_category_id: category_ids })
    end

    if @seed_source_filter.present?
      scope = scope.where(seed_source_id: @seed_source_filter)
    end

    if @year_from_filter.present?
      scope = scope.where("year_purchased >= ?", @year_from_filter.to_i)
    end

    if @year_to_filter.present?
      scope = scope.where("year_purchased <= ?", @year_to_filter.to_i)
    end

    scope
  end

  def apply_sort(scope)
    case @sort
    when "name"
      scope.reorder("plants.name ASC").references(:plant)
    when "category"
      scope.joins(plant: :plant_category).reorder("plant_categories.name ASC, plants.name ASC")
    when "source"
      scope.reorder("seed_sources.name ASC").references(:seed_source)
    when "year"
      scope.reorder(year_purchased: :asc)
    else # "urgency" - most expired first
      scope.reorder(year_purchased: :asc)
    end
  end

  def filter_params
    params.permit(:viability, :plant_type_id, :plant_category_id, :seed_source_id, :year_from, :year_to, :sort)
  end

  helper_method :filter_params_for_redirect

  def filter_params_for_redirect
    filter_params.to_h.compact_blank
  end
end
