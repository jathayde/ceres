class BulkGrowingGuideResearchJob < ApplicationJob
  queue_as :default

  def perform
    guideables = categories_missing_guides + subcategories_missing_guides

    guideables.each do |guideable|
      GrowingGuideResearchJob.perform_later(guideable.id, guideable.class.name)
    end

    guideables.size
  end

  private

  def categories_missing_guides
    PlantCategory.where.missing(:growing_guide).to_a
  end

  def subcategories_missing_guides
    PlantSubcategory.where.missing(:growing_guide).to_a
  end
end
