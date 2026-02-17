class ViabilityBadgeComponent < ViewComponent::Base
  STYLES = {
    viable: "bg-green-100 text-green-800",
    test: "bg-amber-100 text-amber-800",
    expired: "bg-red-100 text-red-800",
    used_up: "bg-gray-100 text-gray-500",
    unknown: "bg-gray-100 text-gray-500"
  }.freeze

  LABELS = {
    viable: "Viable",
    test: "Test",
    expired: "Expired",
    used_up: "Used Up",
    unknown: "Unknown"
  }.freeze

  def initialize(status:)
    @status = status.to_sym
  end

  def call
    tag.span LABELS[@status],
      class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{STYLES[@status]}"
  end
end
