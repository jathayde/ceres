class PlantCategory < ApplicationRecord
  include Sluggable

  belongs_to :plant_type
  has_one :growing_guide, dependent: :destroy
  has_many :plant_subcategories, dependent: :restrict_with_error
  has_many :plants, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :plant_type_id }
  validates :slug, presence: true, uniqueness: { scope: :plant_type_id }

  default_scope { order(:name) }

  def deletable?
    plants.empty? && plant_subcategories.empty?
  end
end
