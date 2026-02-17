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
end
