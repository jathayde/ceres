class NavBarComponent < ViewComponent::Base
  NavItem = Data.define(:label, :path, :active)

  def initialize(current_path:)
    @current_path = current_path
  end

  def nav_items
    [
      NavItem.new(label: "Inventory", path: root_path, active: @current_path == root_path || @current_path.start_with?(inventory_browse_path)),
      NavItem.new(label: "Seed Sources", path: seed_sources_path, active: @current_path.start_with?(seed_sources_path)),
      NavItem.new(label: "Viability Audit", path: viability_audit_path, active: @current_path.start_with?(viability_audit_path))
    ]
  end

  private

  def root_path
    helpers.root_path
  end

  def seed_sources_path
    helpers.seed_sources_path
  end

  def inventory_browse_path
    helpers.inventory_browse_path
  end

  def viability_audit_path
    helpers.viability_audit_path
  end
end
