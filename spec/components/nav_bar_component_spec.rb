require "rails_helper"

RSpec.describe NavBarComponent, type: :component do
  context "when on the inventory page" do
    before { render_inline(described_class.new(current_path: "/")) }

    it "renders the Ceres logo and brand" do
      expect(page).to have_link(href: "/")
      expect(page).to have_text("Ceres")
    end

    it "renders all nav links" do
      expect(page).to have_link("Inventory", href: "/")
      expect(page).to have_link("Seed Sources", href: "/seed_sources")
      expect(page).to have_link("Viability Audit", href: "/viability_audit")
    end

    it "highlights the Inventory link as active" do
      inventory_link = page.find("a", text: "Inventory", match: :first)
      expect(inventory_link[:class]).to include("bg-green-50")
    end

    it "does not highlight other links" do
      sources_link = page.find("a", text: "Seed Sources", match: :first)
      expect(sources_link[:class]).not_to include("bg-green-50")
    end

    it "renders a mobile menu toggle button" do
      expect(page).to have_css("button[data-action='nav-toggle#toggle']")
    end
  end

  context "when on the seed sources page" do
    before { render_inline(described_class.new(current_path: "/seed_sources")) }

    it "highlights the Seed Sources link as active" do
      sources_link = page.find("a", text: "Seed Sources", match: :first)
      expect(sources_link[:class]).to include("bg-green-50")
    end

    it "does not highlight the Inventory link" do
      inventory_link = page.find("a", text: "Inventory", match: :first)
      expect(inventory_link[:class]).not_to include("bg-green-50")
    end
  end

  context "when on the viability audit page" do
    before { render_inline(described_class.new(current_path: "/viability_audit")) }

    it "highlights the Viability Audit link as active" do
      audit_link = page.find("a", text: "Viability Audit", match: :first)
      expect(audit_link[:class]).to include("bg-green-50")
    end
  end
end
