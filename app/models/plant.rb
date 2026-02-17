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

  scope :heirloom, -> { where(heirloom: true) }
  scope :with_seed_source, ->(seed_source_id) {
    where(id: SeedPurchase.where(seed_source_id: seed_source_id, used_up: false).select(:plant_id))
  }
  scope :with_viability_status, ->(status) {
    where("plants.id IN (#{viability_subquery_sql(status)})")
  }

  def self.viability_subquery_sql(status)
    current_year = Date.current.year
    age_expr = "#{current_year} - sp.year_purchased"
    viability_expr = "COALESCE(p.expected_viability_years, pc.expected_viability_years)"

    condition = case status.to_sym
    when :viable
      "#{age_expr} <= #{viability_expr} AND #{viability_expr} IS NOT NULL"
    when :test
      "#{age_expr} > #{viability_expr} AND #{age_expr} <= #{viability_expr} + 2 AND #{viability_expr} IS NOT NULL"
    when :expired
      "#{age_expr} > #{viability_expr} + 2 AND #{viability_expr} IS NOT NULL"
    else
      "1=0"
    end

    <<~SQL.squish
      SELECT sp.plant_id FROM seed_purchases sp
      INNER JOIN plants p ON p.id = sp.plant_id
      INNER JOIN plant_categories pc ON pc.id = p.plant_category_id
      WHERE sp.used_up = FALSE AND (#{condition})
    SQL
  end

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
