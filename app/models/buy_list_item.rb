class BuyListItem < ApplicationRecord
  belongs_to :plant_category, optional: true
  belongs_to :plant_subcategory, optional: true
  belongs_to :plant, optional: true
  belongs_to :seed_purchase, optional: true

  enum :status, { pending: 0, purchased: 1 }

  before_validation :clear_redundant_targets

  validate :exactly_one_target

  def target
    plant || plant_subcategory || plant_category
  end

  def target_name
    target&.name
  end

  def target_level
    if plant_id?
      :variety
    elsif plant_subcategory_id?
      :subcategory
    else
      :category
    end
  end

  def needs_variety_selection?
    !plant_id?
  end

  def mark_purchased!(seed_purchase)
    update!(
      status: :purchased,
      purchased_at: Time.current,
      seed_purchase: seed_purchase
    )
  end

  def self.fulfill_items(item_params_list, seed_source_id:, year_purchased:)
    created = []

    transaction do
      item_params_list.each do |item_data|
        next if item_data[:skip] == "1"

        buy_list_item = pending.find(item_data[:buy_list_item_id])
        plant_id = item_data[:plant_id].presence || buy_list_item.plant_id

        unless plant_id
          raise ActiveRecord::RecordInvalid.new(buy_list_item),
            "Plant is required for #{buy_list_item.target_name}"
        end

        purchase = SeedPurchase.create!(
          plant_id: plant_id,
          seed_source_id: seed_source_id,
          year_purchased: year_purchased,
          packet_count: item_data[:packet_count].presence || 1,
          seed_count: item_data[:seed_count].presence,
          weight_oz: item_data[:weight_oz].presence,
          cost_cents: item_data[:cost_cents].presence,
          notes: item_data[:notes].presence
        )

        buy_list_item.mark_purchased!(purchase)
        created << purchase
      end
    end

    created
  end

  private

  def clear_redundant_targets
    if plant_id?
      self.plant_category_id = nil
      self.plant_subcategory_id = nil
    elsif plant_subcategory_id?
      self.plant_category_id = nil
    end
  end

  def exactly_one_target
    targets = [ plant_category_id, plant_subcategory_id, plant_id ].compact
    if targets.empty?
      errors.add(:base, "must belong to a plant category, plant subcategory, or plant")
    elsif targets.size > 1
      errors.add(:base, "must belong to exactly one of plant category, plant subcategory, or plant")
    end
  end
end
