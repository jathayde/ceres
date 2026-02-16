# Ceres — Seed Inventory Management

## Overview

Ceres is a single-user seed inventory and reference application built with Rails 8 + PostgreSQL. It replaces an 18+ year Excel spreadsheet for managing a personal seed collection of 650+ varieties across vegetables, grains, herbs, flowers, and cover crops. The app tracks what seeds you have, where they came from, whether they're still viable, and how to grow them. It is not a planting journal or garden planner — it's the reference library and inventory system.

**Tech Stack:** Rails 8 (Hotwire/Turbo), PostgreSQL 16+, Solid Queue, Tailwind CSS + ViewComponent, pg_search, RSpec, Anthropic Claude API for AI features. No authentication in v1 (localhost use only).

---

## User Stories

### US-001: Initialize Rails 8 Application
**Priority:** 1
**Description:** As a developer, I want a properly configured Rails 8 application so that I have a foundation to build features on.

**Acceptance Criteria:**
- [ ] Rails 8 app created with PostgreSQL as the database
- [ ] Solid Queue configured for background jobs
- [ ] Tailwind CSS installed and configured
- [ ] PostgreSQL database created and connectable
- [ ] Hotwire/Turbo available (ships with Rails 8)
- [ ] Basic health check route works (root path renders)
- [ ] RSpec configured for testing (rspec-rails gem)
- [ ] shoulda-matchers gem configured for expressive model specs
- [ ] faker gem added for test data generation
- [ ] factory_bot_rails gem configured for test factories
- [ ] pg_search gem added to Gemfile
- [ ] ViewComponent gem installed and configured
- [ ] Anthropic Ruby SDK gem (anthropic) added to Gemfile

---

### US-002: Create PlantType Model and Seed Data
**Priority:** 2
**Description:** As a developer, I want the PlantType model and seed data so that the top-level taxonomy is available for categorizing plants.

**Acceptance Criteria:**
- [ ] PlantType model with columns: name (string, unique, not null), description (text), position (integer), timestamps
- [ ] Database migration runs cleanly
- [ ] Seed data includes: Vegetable, Grain, Herb, Flower, Cover Crop
- [ ] Model validations: name presence and uniqueness
- [ ] Default ordering by position
- [ ] Model tests pass

---

### US-003: Create PlantCategory Model
**Priority:** 3
**Description:** As a developer, I want the PlantCategory model so that plants can be grouped within their type (e.g., Vegetable > Bean, Vegetable > Pepper).

**Acceptance Criteria:**
- [ ] PlantCategory model with columns: plant_type_id (FK, not null), name (string, not null), latin_genus (string), latin_species (string), expected_viability_years (integer), description (text), position (integer), timestamps
- [ ] belongs_to :plant_type association
- [ ] PlantType has_many :plant_categories
- [ ] Validates name presence, uniqueness scoped to plant_type_id
- [ ] Default ordering by position
- [ ] Model tests pass

---

### US-004: Create PlantSubcategory Model
**Priority:** 4
**Description:** As a developer, I want the PlantSubcategory model so that categories can be optionally further subdivided (e.g., Bean > Bush Bean, Bean > Pole Bean).

**Acceptance Criteria:**
- [ ] PlantSubcategory model with columns: plant_category_id (FK, not null), name (string, not null), description (text), position (integer), timestamps
- [ ] belongs_to :plant_category association
- [ ] PlantCategory has_many :plant_subcategories
- [ ] Validates name presence, uniqueness scoped to plant_category_id
- [ ] Default ordering by position
- [ ] Model tests pass

---

### US-005: Create Plant (Variety) Model
**Priority:** 5
**Description:** As a developer, I want the Plant model so that individual named varieties can be stored with their botanical and growing metadata.

**Acceptance Criteria:**
- [ ] Plant model with columns: plant_category_id (FK, not null), plant_subcategory_id (FK, nullable), name (string, not null), latin_name (string), heirloom (boolean, default false), days_to_harvest_min (integer), days_to_harvest_max (integer), winter_hardy (enum: hardy/semi_hardy/tender, nullable), life_cycle (enum: annual/biennial/perennial, not null), planting_seasons (string array), expected_viability_years (integer), references (text array), notes (text), timestamps
- [ ] belongs_to :plant_category, belongs_to :plant_subcategory (optional)
- [ ] PlantCategory has_many :plants
- [ ] PlantSubcategory has_many :plants
- [ ] Validates name presence, life_cycle presence
- [ ] Enum definitions for winter_hardy and life_cycle
- [ ] Model tests pass

---

### US-006: Create SeedSource Model
**Priority:** 6
**Description:** As a developer, I want the SeedSource model so that seed suppliers can be tracked and deduplicated across purchases.

**Acceptance Criteria:**
- [ ] SeedSource model with columns: name (string, unique, not null), url (string), notes (text), timestamps
- [ ] Validates name presence and uniqueness
- [ ] Model tests pass

---

### US-007: Create SeedPurchase Model
**Priority:** 7
**Description:** As a developer, I want the SeedPurchase model so that individual seed acquisitions can be tracked with their inventory state.

**Acceptance Criteria:**
- [ ] SeedPurchase model with columns: plant_id (FK, not null), seed_source_id (FK, not null), year_purchased (integer, not null), lot_number (string), germination_rate (decimal 5,4), weight_oz (decimal), seed_count (integer), packet_count (integer, default 1), cost_cents (integer), used_up (boolean, default false), used_up_at (date), reorder_url (string), notes (text), timestamps
- [ ] belongs_to :plant, belongs_to :seed_source associations
- [ ] Plant has_many :seed_purchases, SeedSource has_many :seed_purchases
- [ ] Validates year_purchased presence, plant and seed_source presence
- [ ] Germination rate between 0 and 1 when present
- [ ] Model tests pass

---

### US-008: Create GrowingGuide Model
**Priority:** 8
**Description:** As a developer, I want the GrowingGuide model so that structured growing information can be stored for each plant variety.

**Acceptance Criteria:**
- [ ] GrowingGuide model with columns: plant_id (FK, unique, not null), overview (text), soil_requirements (text), sun_exposure (enum: full_sun/partial_shade/full_shade), water_needs (enum: low/moderate/high), spacing_inches (integer), row_spacing_inches (integer), planting_depth_inches (decimal), germination_temp_min_f (integer), germination_temp_max_f (integer), germination_days_min (integer), germination_days_max (integer), growing_tips (text), harvest_notes (text), seed_saving_notes (text), ai_generated (boolean, default false), ai_generated_at (datetime), timestamps
- [ ] belongs_to :plant (unique constraint)
- [ ] Plant has_one :growing_guide
- [ ] Enum definitions for sun_exposure and water_needs
- [ ] Model tests pass

---

### US-009: Seed Viability Calculation Logic
**Priority:** 9
**Description:** As a user, I want each seed purchase to show its viability status (viable, test, expired) so that I know which seeds are still good and which need attention.

**Acceptance Criteria:**
- [ ] SeedPurchase has a `viability_status` method that returns :viable, :test, or :expired
- [ ] Viability uses plant-level expected_viability_years, falling back to category-level
- [ ] Viable: age <= expected_years
- [ ] Test: age > expected_years AND age <= expected_years + 2
- [ ] Expired: age > expected_years + 2
- [ ] Purchases marked as used_up are excluded from viability assessment (or show as "used up")
- [ ] SeedPurchase has a `viability_years_remaining` method
- [ ] Viability is computed dynamically (not stored), based on current year
- [ ] Model tests cover all three status tiers plus edge cases

---

### US-010: Seed Default Viability Data Seeding
**Priority:** 10
**Description:** As a user, I want plant categories seeded with species-typical viability years so that viability calculations work out of the box.

**Acceptance Criteria:**
- [ ] Seed data populates expected_viability_years on PlantCategory records
- [ ] Includes at minimum: Onion/Leek/Chive (2), Parsnip/Salsify (2), Corn (3), Carrot/Celery (4), Pepper (3), Bean/Pea (4), Lettuce/Endive (5), Brassicas (5), Beet/Chard (5), Tomato/Eggplant (5), Cucurbits (6), Radish/Turnip (5)
- [ ] Seed data also creates corresponding PlantType associations
- [ ] Seed task is idempotent (re-runnable without duplicates)

---

### US-011: Application Layout and Navigation
**Priority:** 11
**Description:** As a user, I want a clean application layout with navigation so that I can move between the main sections of the app.

**Acceptance Criteria:**
- [ ] Application layout with header navigation
- [ ] Nav links to: Inventory (home), Seed Sources, Viability Audit
- [ ] Tailwind CSS styled, clean and functional
- [ ] Reusable UI elements built as ViewComponents (e.g., nav bar, viability badge, page header)
- [ ] Responsive layout that works on desktop and tablet
- [ ] Active nav state indicates current section

---

### US-012: Plant Taxonomy Management (Admin CRUD)
**Priority:** 12
**Description:** As a user, I want to manage plant types, categories, and subcategories so that I can organize my seed inventory taxonomy.

**Acceptance Criteria:**
- [ ] CRUD interface for PlantType (list, create, edit, delete)
- [ ] CRUD interface for PlantCategory nested under PlantType (list, create, edit, delete)
- [ ] CRUD interface for PlantSubcategory nested under PlantCategory (list, create, edit, delete)
- [ ] PlantCategory form includes latin_genus, latin_species, expected_viability_years
- [ ] Drag-to-reorder or position field for sort order
- [ ] Cannot delete a type/category/subcategory that has associated plants
- [ ] Uses Turbo Frames for inline editing without full page reloads

---

### US-013: Seed Source Management
**Priority:** 13
**Description:** As a user, I want to manage my seed suppliers so that I can track where my seeds come from.

**Acceptance Criteria:**
- [ ] List all seed sources with name, URL, and count of active (not used-up) purchases
- [ ] Create new seed source with name (required), URL, notes
- [ ] Edit existing seed source
- [ ] Delete seed source (only if no associated purchases)
- [ ] Clickable link to supplier website
- [ ] Sorted alphabetically by name

---

### US-014: Plant (Variety) CRUD
**Priority:** 14
**Description:** As a user, I want to create and manage plant varieties so that I can build my seed inventory catalog.

**Acceptance Criteria:**
- [ ] Create new plant: select plant category (required), optionally select subcategory, enter name (required), life_cycle (required), and all optional fields
- [ ] Category dropdown filtered by plant type selection
- [ ] Subcategory dropdown filtered by category selection (hidden if category has no subcategories)
- [ ] Edit all plant fields
- [ ] Delete plant (only if no associated seed purchases)
- [ ] Plant form includes: heirloom checkbox, days to harvest range, winter hardiness, planting seasons multi-select, expected viability years override, references URLs, notes
- [ ] Uses Turbo for dynamic form updates (cascading dropdowns)

---

### US-015: Seed Purchase CRUD
**Priority:** 15
**Description:** As a user, I want to add and manage seed purchases so that I can track my inventory of seeds for each variety.

**Acceptance Criteria:**
- [ ] Add new purchase from plant detail page: select seed source (with typeahead/search), enter year_purchased (required), lot_number, germination_rate, weight or seed count, packet count, cost, reorder URL, notes
- [ ] Also add purchase from a standalone form with plant typeahead selection
- [ ] Edit purchase details
- [ ] Delete purchase
- [ ] Viability badge displayed on each purchase record
- [ ] Seed source can be created inline if it doesn't exist yet

---

### US-016: Mark Seed Purchase as Used Up
**Priority:** 16
**Description:** As a user, I want to mark seed purchases as used up so that my inventory reflects what I actually have on hand.

**Acceptance Criteria:**
- [ ] "Mark as used up" button on each active seed purchase
- [ ] Sets used_up to true and used_up_at to current date
- [ ] Can undo: "Mark as active" button on used-up purchases
- [ ] Used-up purchases are visually dimmed but still visible in purchase history
- [ ] Bulk "mark as used up" action for selecting multiple purchases at once

---

### US-017: Inventory Browser — Hierarchical Navigation
**Priority:** 17
**Description:** As a user, I want to browse my seed inventory through the plant taxonomy hierarchy so that I can find varieties by type and category.

**Acceptance Criteria:**
- [ ] Sidebar or collapsible tree showing PlantType > PlantCategory > PlantSubcategory hierarchy
- [ ] Clicking a type shows all categories within it
- [ ] Clicking a category shows all plants within it (and its subcategories)
- [ ] Clicking a subcategory shows only plants in that subcategory
- [ ] Plant list shows: variety name, latin name, heirloom badge, viability status summary, active purchase count
- [ ] Breadcrumb navigation showing current position in hierarchy
- [ ] Uses Turbo Frames so navigation doesn't cause full page reloads

---

### US-018: Full-Text Search
**Priority:** 18
**Description:** As a user, I want to search across my entire seed inventory so that I can quickly find any variety, source, or note.

**Acceptance Criteria:**
- [ ] Search bar prominently placed in the header or inventory browser
- [ ] Searches across: plant name, latin name, plant notes, seed source name
- [ ] Uses PostgreSQL full-text search (pg_search gem)
- [ ] Results show plant name, category, viability summary, and matching context
- [ ] Search is fast (< 500ms for the expected dataset size)
- [ ] Empty search shows all plants
- [ ] Search works with Turbo for instant results

---

### US-019: Inventory Quick Filters
**Priority:** 19
**Description:** As a user, I want to filter my inventory by viability status, heirloom flag, and seed source so that I can quickly narrow down to what I'm looking for.

**Acceptance Criteria:**
- [ ] Filter buttons/toggles for: Viable Only, Needs Testing, Expired, Heirloom
- [ ] Dropdown filter for seed source
- [ ] Filters combine with each other (AND logic)
- [ ] Filters combine with search
- [ ] Filters combine with taxonomy navigation
- [ ] Active filters are visually indicated
- [ ] Clear all filters button
- [ ] Filters applied via Turbo without full page reload

---

### US-020: Plant Detail View
**Priority:** 20
**Description:** As a user, I want a comprehensive detail page for each plant variety so that I can see all information and purchase history in one place.

**Acceptance Criteria:**
- [ ] Plant metadata section: name, latin name, heirloom badge, life cycle, winter hardiness, planting seasons, days to harvest range
- [ ] Growing guide section: rendered as a readable card with all GrowingGuide fields (if populated), or placeholder if not yet researched
- [ ] Seed purchases table: all purchases sorted by year descending, each showing viability badge, source name (linked), year, lot, quantity info, cost, and used-up status
- [ ] Quick actions: "Add Purchase" button, "Edit Plant" link, "Research Growing Guide" button (triggers AI), edit notes inline
- [ ] Back navigation to inventory browser preserving filter/navigation state

---

### US-021: AI Growing Guide Research
**Priority:** 21
**Description:** As a user, I want to trigger AI research for a plant variety so that its growing guide is auto-populated with structured cultivation data.

**Acceptance Criteria:**
- [ ] "Research Growing Guide" button on plant detail page
- [ ] Dispatches a Solid Queue background job
- [ ] Job calls the Anthropic Claude API with plant name, latin name, and category context
- [ ] AI response is parsed into GrowingGuide schema fields via structured prompting
- [ ] GrowingGuide record is created/updated with ai_generated: true and ai_generated_at timestamp
- [ ] UI shows a loading/pending state while research is in progress (Turbo Stream update on completion)
- [ ] User can re-trigger research to refresh data
- [ ] All AI-populated fields remain user-editable
- [ ] Anthropic API key configured via Rails credentials or ANTHROPIC_API_KEY env var
- [ ] Graceful error handling if AI service is unavailable

---

### US-022: AI Latin Name Lookup
**Priority:** 22
**Description:** As a user, I want the AI to suggest latin names when I add a plant with only a common name so that botanical data is filled in automatically.

**Acceptance Criteria:**
- [ ] When a plant is saved without a latin_name, a background job is enqueued to look it up
- [ ] AI suggests latin_name for the plant variety
- [ ] AI can also suggest latin_genus/latin_species for the parent PlantCategory if missing
- [ ] Suggestion is saved automatically but user is notified it was AI-populated
- [ ] User can override the AI-suggested value at any time

---

### US-023: AI Viability Data Enrichment
**Priority:** 23
**Description:** As a user, I want the AI to suggest viability years for categories or varieties where it's missing so that viability calculations cover my whole inventory.

**Acceptance Criteria:**
- [ ] When a PlantCategory has no expected_viability_years, AI can be triggered to research it
- [ ] AI returns a suggested value based on published horticultural sources
- [ ] Value is saved to the category with a note that it was AI-suggested
- [ ] User can override at category or plant level

---

### US-024: Viability Dashboard / Audit View
**Priority:** 24
**Description:** As a user, I want a viability-focused view of my inventory so that I can do physical seed audits and decide what to keep, test, or wild-sow.

**Acceptance Criteria:**
- [ ] Summary counts at top: total viable, total needs-testing, total expired
- [ ] Table of all active (not used-up) seed purchases grouped by viability status
- [ ] Color-coded rows: green (viable), amber/yellow (test), red (expired)
- [ ] Sortable by urgency (most expired first), plant name, category, source, year purchased
- [ ] Filterable by plant type, category, seed source, year range
- [ ] Checkbox to mark items as "reviewed" during audit session
- [ ] Quick "mark as used up" action directly from this view
- [ ] Print-friendly / exportable version for physical seed box audits

---

### US-025: Spreadsheet Import — File Upload and Parsing
**Priority:** 25
**Description:** As a user, I want to upload my existing Excel spreadsheet so that my 18+ years of seed data can be imported into Ceres.

**Acceptance Criteria:**
- [ ] Upload form accepts .xlsx files
- [ ] Parses each worksheet tab (Vegetables, Grains, Herbs, Flowers, Cover Crops)
- [ ] Handles inconsistent column layouts across tabs
- [ ] Extracts: variety name, seed source, year/date info, germination data, notes
- [ ] Detects gray-text rows as used-up seeds
- [ ] Parsed data stored in a temporary staging table or in-memory for review
- [ ] Handles the various date formats (datetime, plain year, compound strings)

---

### US-026: Spreadsheet Import — AI-Assisted Mapping and Review
**Priority:** 26
**Description:** As a user, I want AI to help map my spreadsheet data to Ceres's structured data model so that the import is accurate without tedious manual classification.

**Acceptance Criteria:**
- [ ] AI parses variety names into plant + category + subcategory structure
- [ ] AI normalizes seed source names (matching abbreviations, misspellings)
- [ ] AI extracts year_purchased from various date formats
- [ ] Review interface shows each parsed row with AI-suggested mappings
- [ ] User can accept, modify, or reject each mapping
- [ ] Probable duplicates are flagged for manual review
- [ ] New plant types/categories/subcategories can be created during review

---

### US-027: Spreadsheet Import — Confirm and Execute
**Priority:** 27
**Description:** As a user, I want to confirm and execute the import so that my reviewed data is saved to the database as proper Plant and SeedPurchase records.

**Acceptance Criteria:**
- [ ] Confirmation summary shows: X plants to create, Y purchases to create, Z sources to create
- [ ] Import creates PlantCategory/PlantSubcategory records as needed
- [ ] Consolidates duplicate variety rows into single Plant with multiple SeedPurchase records
- [ ] Creates SeedSource records, deduplicating by normalized name
- [ ] Sets used_up: true for gray-text rows
- [ ] Import runs as a background job with progress indicator
- [ ] Rollback on failure (wrapped in transaction)
- [ ] Summary report after import: records created, skipped, errors

---

### US-028: Seed Source Merge
**Priority:** 28
**Description:** As a user, I want to merge duplicate seed sources so that my supplier data stays clean.

**Acceptance Criteria:**
- [ ] Select two or more seed sources to merge
- [ ] Choose which source record to keep as the primary
- [ ] All seed purchases from merged sources are reassigned to the primary
- [ ] Merged (duplicate) source records are deleted
- [ ] Confirmation step before executing merge

---

### US-029: Bulk Mark-as-Used for Seed Audit
**Priority:** 29
**Description:** As a user, I want to bulk-select expired or tested seed purchases and mark them all as used up after a physical audit so that I can clean out my inventory efficiently.

**Acceptance Criteria:**
- [ ] Multi-select checkboxes on viability audit view and inventory browser
- [ ] "Mark selected as used up" bulk action
- [ ] Confirmation dialog showing count of items to be marked
- [ ] All selected purchases updated in a single operation
- [ ] UI updates reflect changes immediately via Turbo

---

### US-030: System Tests for Core Workflows
**Priority:** 30
**Description:** As a developer, I want system/integration tests covering the core user workflows so that I can refactor with confidence.

**Acceptance Criteria:**
- [ ] System test: Browse taxonomy hierarchy and view plant detail
- [ ] System test: Create a new plant with category and add a seed purchase
- [ ] System test: Search for a plant and filter by viability status
- [ ] System test: Mark a purchase as used up and verify inventory updates
- [ ] System test: View viability audit dashboard with correct status badges
- [ ] All tests pass in CI-compatible environment
