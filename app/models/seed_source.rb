class SeedSource < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
