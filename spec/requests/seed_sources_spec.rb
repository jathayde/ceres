require "rails_helper"

RSpec.describe "SeedSources", type: :request do
  describe "GET /seed_sources" do
    it "returns a successful response" do
      get seed_sources_path
      expect(response).to have_http_status(:ok)
    end

    it "displays seed sources" do
      create(:seed_source, name: "Baker Creek")
      get seed_sources_path
      expect(response.body).to include("Baker Creek")
    end

    it "displays seed sources sorted alphabetically" do
      create(:seed_source, name: "Territorial Seeds")
      create(:seed_source, name: "Baker Creek")
      get seed_sources_path
      expect(response.body.index("Baker Creek")).to be < response.body.index("Territorial Seeds")
    end

    it "displays active purchase count" do
      source = create(:seed_source, name: "Baker Creek")
      create(:seed_purchase, seed_source: source, used_up: false)
      create(:seed_purchase, seed_source: source, used_up: true)
      get seed_sources_path
      expect(response.body).to include("1")
    end

    it "displays clickable link to supplier website" do
      create(:seed_source, name: "Baker Creek", url: "https://rareseeds.com")
      get seed_sources_path
      expect(response.body).to include("https://rareseeds.com")
    end
  end

  describe "GET /seed_sources/new" do
    it "returns a successful response" do
      get new_seed_source_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /seed_sources" do
    it "creates a new seed source with valid params" do
      expect {
        post seed_sources_path, params: { seed_source: { name: "Baker Creek", url: "https://rareseeds.com", notes: "Great heirloom variety" } }
      }.to change(SeedSource, :count).by(1)
      expect(response).to redirect_to(seed_sources_path)
    end

    it "does not create with invalid params" do
      expect {
        post seed_sources_path, params: { seed_source: { name: "" } }
      }.not_to change(SeedSource, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create with duplicate name" do
      create(:seed_source, name: "Baker Creek")
      expect {
        post seed_sources_path, params: { seed_source: { name: "Baker Creek" } }
      }.not_to change(SeedSource, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /seed_sources/:id/edit" do
    it "returns a successful response" do
      seed_source = create(:seed_source)
      get edit_seed_source_path(seed_source)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /seed_sources/:id" do
    it "updates the seed source with valid params" do
      seed_source = create(:seed_source, name: "Old Name")
      patch seed_source_path(seed_source), params: { seed_source: { name: "New Name" } }
      expect(seed_source.reload.name).to eq("New Name")
      expect(response).to redirect_to(seed_sources_path)
    end

    it "does not update with invalid params" do
      seed_source = create(:seed_source, name: "Old Name")
      patch seed_source_path(seed_source), params: { seed_source: { name: "" } }
      expect(seed_source.reload.name).to eq("Old Name")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /seed_sources/:id" do
    it "deletes a seed source with no purchases" do
      seed_source = create(:seed_source)
      expect {
        delete seed_source_path(seed_source)
      }.to change(SeedSource, :count).by(-1)
      expect(response).to redirect_to(seed_sources_path)
    end

    it "does not delete a seed source with purchases" do
      seed_source = create(:seed_source)
      create(:seed_purchase, seed_source: seed_source)
      expect {
        delete seed_source_path(seed_source)
      }.not_to change(SeedSource, :count)
      expect(response).to redirect_to(seed_sources_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /seed_sources/merge" do
    it "shows merge confirmation when two or more sources selected" do
      source1 = create(:seed_source, name: "Baker Creek")
      source2 = create(:seed_source, name: "Territorial Seeds")
      get merge_seed_sources_path, params: { source_ids: [ source1.id, source2.id ] }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Baker Creek")
      expect(response.body).to include("Territorial Seeds")
      expect(response.body).to include("Merge Sources")
    end

    it "redirects with alert when fewer than two sources selected" do
      source = create(:seed_source, name: "Baker Creek")
      get merge_seed_sources_path, params: { source_ids: [ source.id ] }
      expect(response).to redirect_to(seed_sources_path)
      expect(flash[:alert]).to eq("Select at least two seed sources to merge.")
    end

    it "redirects with alert when no sources selected" do
      get merge_seed_sources_path
      expect(response).to redirect_to(seed_sources_path)
      expect(flash[:alert]).to eq("Select at least two seed sources to merge.")
    end

    it "shows purchase counts for each source" do
      source1 = create(:seed_source, name: "Source A")
      source2 = create(:seed_source, name: "Source B")
      create(:seed_purchase, seed_source: source1)
      create(:seed_purchase, seed_source: source1)
      create(:seed_purchase, seed_source: source2)
      get merge_seed_sources_path, params: { source_ids: [ source1.id, source2.id ] }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /seed_sources/execute_merge" do
    it "merges sources into the primary" do
      primary = create(:seed_source, name: "Primary")
      other = create(:seed_source, name: "Duplicate")
      purchase = create(:seed_purchase, seed_source: other)

      post execute_merge_seed_sources_path, params: {
        primary_id: primary.id,
        merge_ids: [ primary.id, other.id ]
      }

      expect(response).to redirect_to(seed_sources_path)
      expect(flash[:notice]).to include("Primary")
      expect(purchase.reload.seed_source).to eq(primary)
      expect(SeedSource.exists?(other.id)).to be false
    end

    it "redirects with alert when no other sources to merge" do
      primary = create(:seed_source, name: "Primary")

      post execute_merge_seed_sources_path, params: {
        primary_id: primary.id,
        merge_ids: [ primary.id ]
      }

      expect(response).to redirect_to(seed_sources_path)
      expect(flash[:alert]).to eq("No sources selected to merge.")
    end

    it "merges three or more sources" do
      primary = create(:seed_source, name: "Keep This")
      dup1 = create(:seed_source, name: "Duplicate 1")
      dup2 = create(:seed_source, name: "Duplicate 2")
      p1 = create(:seed_purchase, seed_source: dup1)
      p2 = create(:seed_purchase, seed_source: dup2)

      expect {
        post execute_merge_seed_sources_path, params: {
          primary_id: primary.id,
          merge_ids: [ primary.id, dup1.id, dup2.id ]
        }
      }.to change(SeedSource, :count).by(-2)

      expect(p1.reload.seed_source).to eq(primary)
      expect(p2.reload.seed_source).to eq(primary)
    end
  end

  describe "POST /seed_sources/inline_create" do
    it "creates a seed source and returns JSON" do
      expect {
        post seed_sources_inline_create_path, params: { seed_source: { name: "New Source", url: "https://newsource.com" } }, as: :json
      }.to change(SeedSource, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("New Source")
      expect(json["id"]).to be_present
    end

    it "returns errors for invalid params" do
      post seed_sources_inline_create_path, params: { seed_source: { name: "" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "returns errors for duplicate name" do
      create(:seed_source, name: "Existing Source")
      post seed_sources_inline_create_path, params: { seed_source: { name: "Existing Source" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
