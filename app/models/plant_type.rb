class PlantType < ApplicationRecord
  has_many :plant_categories, dependent: :restrict_with_error
  has_many :plants, through: :plant_categories

  validates :name, presence: true, uniqueness: true

  default_scope { order(:position) }

  def deletable?
    plant_categories.empty?
  end
end
