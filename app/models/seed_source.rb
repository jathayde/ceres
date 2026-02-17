class SeedSource < ApplicationRecord
  has_many :seed_purchases, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }

  def active_purchases_count
    seed_purchases.where(used_up: false).count
  end

  def deletable?
    seed_purchases.empty?
  end
end
