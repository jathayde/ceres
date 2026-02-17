module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, if: -> { name.present? && (slug.blank? || name_changed?) }
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
