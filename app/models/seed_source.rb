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

  def merge_with!(others)
    others = Array(others)
    raise ArgumentError, "cannot merge a source with itself" if others.include?(self)

    ActiveRecord::Base.transaction do
      others.each do |other|
        other.seed_purchases.update_all(seed_source_id: id)
        other.destroy!
      end
    end
  end
end
