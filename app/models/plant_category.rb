class PlantCategory < ApplicationRecord
  belongs_to :plant_type

  validates :name, presence: true, uniqueness: { scope: :plant_type_id }

  default_scope { order(:position) }
end
