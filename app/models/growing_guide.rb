class GrowingGuide < ApplicationRecord
  belongs_to :plant_category, optional: true
  belongs_to :plant_subcategory, optional: true

  enum :sun_exposure, { full_sun: 0, partial_shade: 1, full_shade: 2 }
  enum :water_needs, { low: 0, moderate: 1, high: 2 }

  validates :plant_category_id, uniqueness: true, allow_nil: true
  validates :plant_subcategory_id, uniqueness: true, allow_nil: true
  validate :exactly_one_owner

  def guideable
    plant_subcategory || plant_category
  end

  private

  def exactly_one_owner
    if plant_category_id.blank? && plant_subcategory_id.blank?
      errors.add(:base, "must belong to a plant category or plant subcategory")
    elsif plant_category_id.present? && plant_subcategory_id.present?
      errors.add(:base, "cannot belong to both a plant category and a plant subcategory")
    end
  end
end
