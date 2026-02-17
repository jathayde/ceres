require "rails_helper"

RSpec.describe "Mark a purchase as used up and verify inventory updates", type: :request do
  let!(:vegetable_type) { create(:plant_type, name: "Vegetable", position: 1) }
  let!(:tomato_category) { create(:plant_category, plant_type: vegetable_type, name: "Tomato", expected_viability_years: 5, position: 1) }
  let!(:seed_source) { create(:seed_source, name: "Baker Creek") }

  let!(:cherokee_purple) do
    create(:plant, name: "Cherokee Purple", plant_category: tomato_category, life_cycle: :annual)
  end

  let!(:active_purchase) do
    create(:seed_purchase, plant: cherokee_purple, seed_source: seed_source, year_purchased: Date.current.year, used_up: false)
  end
  let!(:second_purchase) do
    create(:seed_purchase, plant: cherokee_purple, seed_source: seed_source, year_purchased: Date.current.year - 1, used_up: false)
  end

  describe "marking a single purchase as used up" do
    it "marks the purchase as used up and redirects" do
      patch mark_as_used_up_seed_purchase_path(active_purchase)

      expect(response).to redirect_to(seed_purchases_path)
      follow_redirect!
      expect(response.body).to include("marked as used up")

      active_purchase.reload
      expect(active_purchase.used_up).to be true
      expect(active_purchase.used_up_at).to eq(Date.current)
    end

    it "shows used up status on the plant detail page" do
      patch mark_as_used_up_seed_purchase_path(active_purchase)

      get inventory_variety_path(vegetable_type.slug, tomato_category.slug, cherokee_purple.slug)
      expect(response.body).to include("Mark Active")
      expect(response.body).to include("Used Up")
    end

    it "preserves the other active purchase" do
      patch mark_as_used_up_seed_purchase_path(active_purchase)

      second_purchase.reload
      expect(second_purchase.used_up).to be false
    end
  end

  describe "marking a purchase as active again" do
    before do
      active_purchase.update!(used_up: true, used_up_at: Date.current)
    end

    it "restores the purchase to active status" do
      patch mark_as_active_seed_purchase_path(active_purchase)

      expect(response).to redirect_to(seed_purchases_path)
      follow_redirect!
      expect(response.body).to include("marked as active")

      active_purchase.reload
      expect(active_purchase.used_up).to be false
      expect(active_purchase.used_up_at).to be_nil
    end
  end

  describe "inventory reflects used-up changes" do
    it "shows correct active purchase count after marking used up" do
      # Before: 2 active purchases
      get root_path
      expect(response.body).to include("Cherokee Purple")

      # Mark one as used up
      patch mark_as_used_up_seed_purchase_path(active_purchase)

      # After: 1 active purchase remains
      get inventory_variety_path(vegetable_type.slug, tomato_category.slug, cherokee_purple.slug)
      expect(response.body).to include("Mark Used Up")
      expect(response.body).to include("Mark Active")
    end

    it "viability audit no longer shows used-up purchase" do
      # Before: purchase shows in audit
      get viability_audit_path
      expect(response.body).to include("Cherokee Purple")

      # Mark both as used up
      patch mark_as_used_up_seed_purchase_path(active_purchase)
      patch mark_as_used_up_seed_purchase_path(second_purchase)

      # After: no purchases in audit
      get viability_audit_path
      expect(response.body).to include("No active seed purchases to audit")
    end
  end

  describe "marking used up from viability audit" do
    it "marks a purchase as used up from the audit view" do
      patch viability_audit_mark_as_used_up_path(active_purchase)

      expect(response).to redirect_to(viability_audit_path)
      follow_redirect!
      expect(response.body).to include("marked as used up")

      active_purchase.reload
      expect(active_purchase.used_up).to be true
    end
  end

  describe "bulk mark as used up from inventory" do
    it "marks all active purchases for selected plants" do
      patch bulk_mark_used_up_inventory_path, params: {
        plant_ids: [ cherokee_purple.id ]
      }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("2 purchases marked as used up")

      active_purchase.reload
      second_purchase.reload
      expect(active_purchase.used_up).to be true
      expect(second_purchase.used_up).to be true
    end

    it "shows alert when no plants selected" do
      patch bulk_mark_used_up_inventory_path, params: { plant_ids: nil }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("No plants were selected")
    end
  end

  describe "bulk mark as used up from viability audit" do
    it "marks selected purchases as used up" do
      patch viability_audit_bulk_mark_used_up_path, params: {
        seed_purchase_ids: [ active_purchase.id, second_purchase.id ]
      }

      expect(response).to redirect_to(viability_audit_path)
      follow_redirect!
      expect(response.body).to include("2 purchases marked as used up")

      active_purchase.reload
      second_purchase.reload
      expect(active_purchase.used_up).to be true
      expect(second_purchase.used_up).to be true
    end
  end
end
