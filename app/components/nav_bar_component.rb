class NavBarComponent < ViewComponent::Base
  NavItem = Data.define(:label, :path, :active)

  def initialize(current_path:)
    @current_path = current_path
  end

  def nav_items
    [
      NavItem.new(label: "Inventory", path: root_path, active: @current_path == root_path || @current_path.start_with?(inventory_browse_path)),
      NavItem.new(label: "Seed Sources", path: seed_sources_path, active: @current_path.start_with?(seed_sources_path)),
      NavItem.new(label: "Viability Audit", path: viability_audit_path, active: @current_path.start_with?(viability_audit_path)),
      NavItem.new(label: "Buy List", path: buy_list_items_path, active: @current_path.start_with?(buy_list_items_path)),
      NavItem.new(label: "Import", path: new_spreadsheet_import_path, active: @current_path.start_with?(spreadsheet_imports_path)),
      NavItem.new(label: "Settings", path: admin_path, active: @current_path.start_with?(admin_path))
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

  def new_spreadsheet_import_path
    helpers.new_spreadsheet_import_path
  end

  def spreadsheet_imports_path
    helpers.spreadsheet_imports_path
  end

  def buy_list_items_path
    helpers.buy_list_items_path
  end

  def admin_path
    helpers.admin_path
  end
end
