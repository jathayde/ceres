class PlantSubcategory < ApplicationRecord
  belongs_to :plant_category
  has_many :plants, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :plant_category_id }

  default_scope { order(:position) }
end
