module ApplicationHelper
  LEVEL_BADGE_CLASSES = {
    category: "bg-blue-100 text-blue-800",
    subcategory: "bg-purple-100 text-purple-800",
    variety: "bg-green-100 text-green-800"
  }.freeze

  def level_badge(level)
    tag.span level.to_s.capitalize,
      class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{LEVEL_BADGE_CLASSES[level]}"
  end
end
