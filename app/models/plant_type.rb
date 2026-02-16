class PlantType < ApplicationRecord
  has_many :plant_categories, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  default_scope { order(:position) }
end
