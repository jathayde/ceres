class GrowingGuide < ApplicationRecord
  belongs_to :plant

  enum :sun_exposure, { full_sun: 0, partial_shade: 1, full_shade: 2 }
  enum :water_needs, { low: 0, moderate: 1, high: 2 }

  validates :plant_id, uniqueness: true
end
