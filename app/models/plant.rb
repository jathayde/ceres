class Plant < ApplicationRecord
  belongs_to :plant_category
  belongs_to :plant_subcategory, optional: true

  has_one :growing_guide, dependent: :destroy
  has_many :seed_purchases, dependent: :restrict_with_error

  enum :winter_hardy, { hardy: 0, semi_hardy: 1, tender: 2 }
  enum :life_cycle, { annual: 0, biennial: 1, perennial: 2 }

  PLANTING_SEASON_OPTIONS = %w[Spring Summer Fall Winter].freeze

  validates :name, presence: true
  validates :life_cycle, presence: true

  def deletable?
    seed_purchases.empty?
  end

  def active_purchases
    seed_purchases.reject(&:used_up?)
  end

  def best_viability_status
    statuses = active_purchases.map(&:viability_status)
    return nil if statuses.empty?
    return :viable if statuses.include?(:viable)
    return :test if statuses.include?(:test)
    return :expired if statuses.include?(:expired)

    :unknown
  end
end
