# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ceres is a single-user seed inventory management app built with Rails 8.1 + PostgreSQL. It replaces an 18+ year Excel spreadsheet for managing ~650+ seed varieties. No authentication in v1 (localhost-only). Product requirements live in `.chief/prds/main/prd.md` (30 user stories, US-001 through US-030).

## Commands

### Development
```bash
bin/rails server                    # Start on localhost:3000
foreman start -f Procfile.dev       # Web server + Tailwind CSS watcher
```

### Testing
```bash
bin/rspec                           # Run all specs
bin/rspec spec/models/              # Run model specs
bin/rspec spec/requests/            # Run request specs
bin/rspec spec/requests/workflows/  # Run workflow integration tests
bin/rspec spec/path/to_spec.rb:42   # Run single example by line number
bin/rspec --fail-fast               # Stop on first failure
```

### Linting & Security
```bash
bin/rubocop -f github               # Lint (rubocop-rails-omakase style)
bin/brakeman --no-pager             # Security vulnerability scan
bin/bundler-audit                   # Gem vulnerability check
bin/importmap audit                 # JS dependency audit
```

### Database
```bash
bin/rails db:create db:migrate db:seed   # Full setup (PostgreSQL required)
bin/rails db:schema:load                 # Fast setup from schema.rb
```

## Architecture

### Tech Stack
Rails 8.1, Ruby 3.4, PostgreSQL 16+, Hotwire (Turbo + Stimulus), Tailwind CSS, PropShaft, ViewComponent, Solid Queue, pg_search, Anthropic Claude API (via `anthropic` gem).

### Data Model
Three-level plant taxonomy: **PlantType** > **PlantCategory** > **PlantSubcategory** (optional). Plant varieties (`Plant`) belong to a category and optionally a subcategory. Each `SeedPurchase` links a `Plant` to a `SeedSource` with purchase year, quantity, and cost data. `GrowingGuide` is 1:1 with Plant (AI-generated cultivation info). `SpreadsheetImport` + `SpreadsheetImportRow` handle bulk Excel imports with a multi-stage workflow (upload → parse → AI map → confirm → execute).

Taxonomy models use `dependent: :restrict_with_error` — you cannot delete a type/category that has children. Models expose a `deletable?` method that guards the UI delete button.

### Viability System
`SeedPurchase#viability_status` returns `:viable`, `:test`, or `:expired` based on `seed_age` vs `expected_viability_years` (sourced from the plant or its category). `Plant.best_viability_status` aggregates across active (non-used-up) purchases. The viability audit dashboard (`/viability_audit`) filters by status with bulk mark-as-used-up actions.

### Frontend Patterns
- **Turbo Frames** for inline editing and partial page updates (inventory sidebar, row editing)
- **Stimulus controllers** (17 total) for interactivity: `cascading_select` (type→category→subcategory dropdowns), `bulk_select` (checkbox toolbar), `audit_filters` (URL-driven filter state), `search_form` (debounced search), `taxonomy_tree` (collapsible sidebar), `inline_source` (create SeedSource without page reload)
- **ViewComponents**: `NavBarComponent`, `TaxonomySidebarComponent`, `InventoryBreadcrumbComponent`, `PageHeaderComponent`, `ViabilityBadgeComponent`
- Cascading select dropdowns hit `/plants/categories_for_type` and `/plants/subcategories_for_category` JSON endpoints

### Background Jobs (Solid Queue)
- `SpreadsheetParseJob` — extracts rows from uploaded Excel files
- `SpreadsheetMappingJob` — batch AI classification (20 rows/batch) via Anthropic Claude
- `SpreadsheetExecuteJob` — bulk creates Plants, SeedPurchases, SeedSources with duplicate detection
- `GrowingGuideResearchJob`, `LatinNameLookupJob`, `ViabilityDataEnrichmentJob` — AI enrichment jobs

### Routing Structure
- Nested CRUD: `plant_types > plant_categories > plant_subcategories`
- Standalone CRUD: `plants`, `seed_purchases`, `seed_sources`
- Spreadsheet imports: `spreadsheet_imports` with member actions (`start_mapping`, `review`, `update_row_mapping`, `create_taxonomy`, `confirm`, `execute`)
- Root path → `inventory#index`; inventory browse at `/inventory/browse`

### Testing
RSpec with FactoryBot, Shoulda Matchers, Faker, Capybara (for ViewComponent tests). Spec type is inferred from file location. Factories exist for all models in `spec/factories/`. Workflow integration tests in `spec/requests/workflows/` cover core user journeys. `caxlsx` gem generates test Excel fixtures.

### CI (GitHub Actions)
Runs on push to main and PRs: Brakeman, bundler-audit, importmap audit, RuboCop. Tests are not yet in CI.

## Conventions

- RuboCop uses `rubocop-rails-omakase` (Rails default style guide)
- Controllers follow standard CRUD pattern with `before_action :set_*` and strong params
- Search uses `pg_search` multisearch with ranked columns and associated model searches
- AI features use encrypted credentials (`config/credentials.yml.enc`) for the Anthropic API key
- Monetary values stored as integer cents (`cost_cents` column)
- Enum integers for status fields (`life_cycle`, `winter_hardy`, `mapping_status`, `import status`)
