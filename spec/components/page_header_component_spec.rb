require "rails_helper"

RSpec.describe PageHeaderComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new(title: "Inventory"))
    expect(page).to have_css("h1", text: "Inventory")
  end

  it "renders the subtitle when provided" do
    render_inline(described_class.new(title: "Inventory", subtitle: "Browse your seeds"))
    expect(page).to have_text("Browse your seeds")
  end

  it "does not render subtitle section when not provided" do
    render_inline(described_class.new(title: "Inventory"))
    expect(page).not_to have_css("p")
  end

  it "renders actions slot when provided" do
    render_inline(described_class.new(title: "Inventory")) do |c|
      c.with_actions { "<button>Add</button>".html_safe }
    end
    expect(page).to have_button("Add")
  end
end
