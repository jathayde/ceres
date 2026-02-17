class Plant < ApplicationRecord
  include PgSearch::Model

  belongs_to :plant_category
  belongs_to :plant_subcategory, optional: true

  has_one :growing_guide, dependent: :destroy
  has_many :seed_purchases, dependent: :restrict_with_error
  has_many :seed_sources, through: :seed_purchases

  enum :winter_hardy, { hardy: 0, semi_hardy: 1, tender: 2 }
  enum :life_cycle, { annual: 0, biennial: 1, perennial: 2 }

  PLANTING_SEASON_OPTIONS = %w[Spring Summer Fall Winter].freeze

  validates :name, presence: true
  validates :life_cycle, presence: true

  pg_search_scope :search,
    against: { name: "A", latin_name: "B", notes: "C" },
    associated_against: {
      seed_sources: { name: "C" },
      plant_category: { name: "B" }
    },
    using: {
      tsearch: { prefix: true, dictionary: "english" }
    }

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
