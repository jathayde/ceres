class SeedSource < ApplicationRecord
  has_many :seed_purchases, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
