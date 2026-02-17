class PlantSubcategory < ApplicationRecord
  belongs_to :plant_category
  has_one :growing_guide, dependent: :destroy
  has_many :plants, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :plant_category_id }

  default_scope { order(:name) }

  def deletable?
    plants.empty?
  end
end
