class SeedPurchase < ApplicationRecord
  belongs_to :plant
  belongs_to :seed_source

  validates :year_purchased, presence: true
  validates :germination_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
end
