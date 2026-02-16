class SeedPurchase < ApplicationRecord
  belongs_to :plant
  belongs_to :seed_source

  validates :year_purchased, presence: true
  validates :germination_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  def viability_status
    return :used_up if used_up?

    years = expected_viability_years
    return :unknown unless years

    age = seed_age

    if age <= years
      :viable
    elsif age <= years + 2
      :test
    else
      :expired
    end
  end

  def viability_years_remaining
    years = expected_viability_years
    return nil unless years

    years - seed_age
  end

  def seed_age
    Date.current.year - year_purchased
  end

  private

  def expected_viability_years
    plant.expected_viability_years || plant.plant_category.expected_viability_years
  end
end
