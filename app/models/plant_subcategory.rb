class PlantSubcategory < ApplicationRecord
  belongs_to :plant_category

  validates :name, presence: true, uniqueness: { scope: :plant_category_id }

  default_scope { order(:position) }
end
