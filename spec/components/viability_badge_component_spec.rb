require "rails_helper"

RSpec.describe ViabilityBadgeComponent, type: :component do
  %i[viable test expired used_up unknown].each do |status|
    context "with #{status} status" do
      it "renders a badge with the correct label" do
        render_inline(described_class.new(status: status))
        expected_label = { viable: "Viable", test: "Test", expired: "Expired", used_up: "Used Up", unknown: "Unknown" }
        expect(page).to have_text(expected_label[status])
      end
    end
  end

  it "renders with green styling for viable" do
    render_inline(described_class.new(status: :viable))
    expect(page).to have_css("span.bg-green-100.text-green-800")
  end

  it "renders with amber styling for test" do
    render_inline(described_class.new(status: :test))
    expect(page).to have_css("span.bg-amber-100.text-amber-800")
  end

  it "renders with red styling for expired" do
    render_inline(described_class.new(status: :expired))
    expect(page).to have_css("span.bg-red-100.text-red-800")
  end

  it "accepts string status" do
    render_inline(described_class.new(status: "viable"))
    expect(page).to have_text("Viable")
  end
end
