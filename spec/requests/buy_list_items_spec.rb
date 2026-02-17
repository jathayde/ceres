require "rails_helper"

RSpec.describe "BuyListItems", type: :request do
  let!(:plant_type) { create(:plant_type) }
  let!(:plant_category) { create(:plant_category, plant_type: plant_type) }
  let!(:plant_subcategory) { create(:plant_subcategory, plant_category: plant_category) }
  let!(:plant) { create(:plant, plant_category: plant_category) }
  let!(:seed_source) { create(:seed_source) }

  describe "GET /buy-list" do
    it "returns a successful response" do
      get buy_list_items_path
      expect(response).to have_http_status(:ok)
    end

    it "displays pending items by default" do
      item = create(:buy_list_item, plant_category: plant_category)
      get buy_list_items_path
      expect(response.body).to include(plant_category.name)
    end

    it "filters by purchased status" do
      pending_item = create(:buy_list_item, plant_category: plant_category)
      purchased_item = create(:buy_list_item, :purchased, plant_category: create(:plant_category, plant_type: plant_type))
      get buy_list_items_path(status: "purchased")
      expect(response.body).to include(purchased_item.target_name)
      expect(response.body).not_to include(pending_item.target_name)
    end

    it "shows all items with status=all" do
      create(:buy_list_item, plant_category: plant_category)
      create(:buy_list_item, :purchased, plant_category: create(:plant_category, plant_type: plant_type))
      get buy_list_items_path(status: "all")
      expect(response).to have_http_status(:ok)
    end

    it "shows level badges" do
      create(:buy_list_item, plant_category: plant_category)
      get buy_list_items_path
      expect(response.body).to include("Category")
    end
  end

  describe "GET /buy-list/new" do
    it "returns a successful response" do
      get new_buy_list_item_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /buy-list" do
    it "creates a category-level buy list item" do
      expect {
        post buy_list_items_path, params: { buy_list_item: { plant_category_id: plant_category.id, notes: "Need more" } }
      }.to change(BuyListItem, :count).by(1)
      expect(response).to redirect_to(buy_list_items_path)
      expect(BuyListItem.last.notes).to eq("Need more")
    end

    it "creates a subcategory-level buy list item" do
      expect {
        post buy_list_items_path, params: { buy_list_item: { plant_subcategory_id: plant_subcategory.id } }
      }.to change(BuyListItem, :count).by(1)
    end

    it "creates a plant-level buy list item" do
      expect {
        post buy_list_items_path, params: { buy_list_item: { plant_id: plant.id } }
      }.to change(BuyListItem, :count).by(1)
    end

    it "fails without a target" do
      expect {
        post buy_list_items_path, params: { buy_list_item: { notes: "No target" } }
      }.not_to change(BuyListItem, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /buy-list/:id/edit" do
    it "returns a successful response" do
      item = create(:buy_list_item, plant_category: plant_category)
      get edit_buy_list_item_path(item)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /buy-list/:id" do
    it "updates the item" do
      item = create(:buy_list_item, plant_category: plant_category, notes: "Old notes")
      patch buy_list_item_path(item), params: { buy_list_item: { notes: "New notes" } }
      expect(item.reload.notes).to eq("New notes")
      expect(response).to redirect_to(buy_list_items_path)
    end
  end

  describe "DELETE /buy-list/:id" do
    it "deletes the item" do
      item = create(:buy_list_item, plant_category: plant_category)
      expect {
        delete buy_list_item_path(item)
      }.to change(BuyListItem, :count).by(-1)
      expect(response).to redirect_to(buy_list_items_path)
    end
  end

  describe "POST /buy-list/quick_add" do
    it "creates item and redirects back" do
      expect {
        post quick_add_buy_list_items_path, params: { buy_list_item: { plant_category_id: plant_category.id } },
          headers: { "HTTP_REFERER" => root_path }
      }.to change(BuyListItem, :count).by(1)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("added to buy list")
    end

    it "creates plant-level item via quick_add" do
      expect {
        post quick_add_buy_list_items_path, params: { buy_list_item: { plant_id: plant.id } },
          headers: { "HTTP_REFERER" => root_path }
      }.to change(BuyListItem, :count).by(1)
    end

    it "redirects with alert on failure" do
      post quick_add_buy_list_items_path, params: { buy_list_item: { notes: "no target" } },
        headers: { "HTTP_REFERER" => root_path }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Could not add to buy list")
    end
  end

  describe "GET /buy-list/receive" do
    it "shows receive form for selected items" do
      item1 = create(:buy_list_item, plant_category: plant_category)
      item2 = create(:buy_list_item, :for_plant, plant: plant)
      get receive_buy_list_items_path, params: { buy_list_item_ids: [ item1.id, item2.id ] }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(item1.target_name)
      expect(response.body).to include(item2.target_name)
    end

    it "redirects when no items selected" do
      get receive_buy_list_items_path
      expect(response).to redirect_to(buy_list_items_path)
      expect(flash[:alert]).to include("No pending items")
    end

    it "ignores already-purchased items" do
      purchased = create(:buy_list_item, :purchased, plant_category: plant_category)
      get receive_buy_list_items_path, params: { buy_list_item_ids: [ purchased.id ] }
      expect(response).to redirect_to(buy_list_items_path)
    end
  end

  describe "POST /buy-list/fulfill" do
    it "creates seed purchases and marks items as purchased" do
      item = create(:buy_list_item, :for_plant, plant: plant)

      expect {
        post fulfill_buy_list_items_path, params: {
          shared_seed_source_id: seed_source.id,
          shared_year_purchased: Date.current.year,
          items: {
            "0" => {
              buy_list_item_id: item.id,
              plant_id: plant.id,
              packet_count: 2,
              seed_count: 50,
              cost_cents: 499
            }
          }
        }
      }.to change(SeedPurchase, :count).by(1)

      item.reload
      expect(item).to be_purchased
      expect(item.seed_purchase).to be_present
      expect(item.seed_purchase.packet_count).to eq(2)
      expect(response).to redirect_to(buy_list_items_path)
      expect(flash[:notice]).to include("1 purchase created")
    end

    it "skips items with skip flag" do
      item = create(:buy_list_item, :for_plant, plant: plant)

      expect {
        post fulfill_buy_list_items_path, params: {
          shared_seed_source_id: seed_source.id,
          shared_year_purchased: Date.current.year,
          items: {
            "0" => {
              buy_list_item_id: item.id,
              plant_id: plant.id,
              skip: "1"
            }
          }
        }
      }.not_to change(SeedPurchase, :count)

      expect(item.reload).to be_pending
    end

    it "redirects with alert when no items provided" do
      post fulfill_buy_list_items_path, params: {
        shared_seed_source_id: seed_source.id,
        shared_year_purchased: Date.current.year
      }
      expect(response).to redirect_to(buy_list_items_path)
      expect(flash[:alert]).to include("No items to receive")
    end

    it "handles multiple items" do
      item1 = create(:buy_list_item, :for_plant, plant: plant)
      plant2 = create(:plant, plant_category: plant_category)
      item2 = create(:buy_list_item, :for_plant, plant: plant2)

      expect {
        post fulfill_buy_list_items_path, params: {
          shared_seed_source_id: seed_source.id,
          shared_year_purchased: Date.current.year,
          items: {
            "0" => { buy_list_item_id: item1.id, plant_id: plant.id, packet_count: 1 },
            "1" => { buy_list_item_id: item2.id, plant_id: plant2.id, packet_count: 1 }
          }
        }
      }.to change(SeedPurchase, :count).by(2)

      expect(flash[:notice]).to include("2 purchases created")
    end
  end
end
