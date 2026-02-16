class PlantCategory < ApplicationRecord
  belongs_to :plant_type
  has_many :plant_subcategories, dependent: :destroy
  has_many :plants, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :plant_type_id }

  default_scope { order(:position) }
end
