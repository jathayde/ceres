class AdminController < ApplicationController
  def index
    @categories_missing_guides = PlantCategory.where.missing(:growing_guide).count
    @subcategories_missing_guides = PlantSubcategory.where.missing(:growing_guide).count
    @total_missing = @categories_missing_guides + @subcategories_missing_guides
  end

  def research_all_growing_guides
    missing_count = PlantCategory.where.missing(:growing_guide).count +
                    PlantSubcategory.where.missing(:growing_guide).count

    BulkGrowingGuideResearchJob.perform_later

    redirect_to admin_path, notice: "Enqueued growing guide research for #{missing_count} #{"category".pluralize(missing_count)}."
  end
end
