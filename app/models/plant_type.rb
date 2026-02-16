class PlantType < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  default_scope { order(:position) }
end
