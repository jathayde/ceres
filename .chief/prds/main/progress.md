## Codebase Patterns
- Rails 8.1.2 app with PostgreSQL, Tailwind CSS 4, Hotwire/Turbo, Importmap
- RSpec for testing with shoulda-matchers, factory_bot, faker
- Rubocop with rails-omakase style guide — run `bin/rubocop` for linting
- Run `bundle exec rspec` for tests
- Solid Queue for background jobs (production), async adapter in dev/test
- ViewComponent for reusable UI components
- pg_search gem for full-text search
- Anthropic Ruby SDK gem for AI features
- Root route: `home#index`
- Project directory: `/Users/jathayde/Development/HomesteadTrack/ceres`
- Rubocop requires spaces inside array brackets: `[ :a, :b ]` not `[:a, :b]`
- Use `default_scope { order(:position) }` for position-ordered models
- Uniqueness scoped validations: `validates :name, uniqueness: { scope: :parent_id }`
- PostgreSQL array columns: `t.string :field, array: true, default: []`
- Enums: integer column in migration, `enum :field, { key: 0, key2: 1 }` in model
- Use `references_urls` not `references` as column name to avoid Rails method conflict
- Optional belongs_to: `belongs_to :assoc, optional: true` with `null: true` in migration

---

## 2026-02-16 - US-001
- Initialized Rails 8.1.2 application with PostgreSQL
- Configured Tailwind CSS, Hotwire/Turbo, Solid Queue
- Added and configured RSpec with shoulda-matchers, factory_bot, faker
- Added pg_search, view_component, and anthropic gems
- Set up root route to home#index with basic landing page
- Health check available at /up
- Files changed: All initial Rails scaffold files + Gemfile modifications, spec/ setup
- **Learnings for future iterations:**
  - Rails 8 ships with Solid Queue, Solid Cache, Solid Cable out of the box
  - `rails new . --database=postgresql --css=tailwind --skip-test` is the right incantation for this stack
  - Use `bin/rubocop` for linting, `bundle exec rspec` for tests
  - The `.rspec` file has `--require spec_helper`; rails_helper must be required explicitly or via support files
  - `config.infer_spec_type_from_file_location!` was uncommented to enable automatic spec type inference
---

## 2026-02-16 - US-003
- Created PlantCategory model with: plant_type_id (FK, not null), name (string, not null), latin_genus, latin_species, expected_viability_years, description, position
- Added composite unique index on [plant_type_id, name]
- Model validates name presence and uniqueness scoped to plant_type_id
- Default scope orders by position
- Added `has_many :plant_categories, dependent: :destroy` to PlantType
- Created factory and comprehensive model specs (associations, validations, scoped uniqueness, default scope, factory)
- Files changed:
  - `db/migrate/20260216233802_create_plant_categories.rb` (new)
  - `app/models/plant_category.rb` (new)
  - `app/models/plant_type.rb` (updated — added association)
  - `spec/models/plant_category_spec.rb` (new)
  - `spec/models/plant_type_spec.rb` (updated — added association test)
  - `spec/factories/plant_categories.rb` (new)
  - `db/schema.rb` (auto-updated by migration)
- **Learnings for future iterations:**
  - Rubocop enforces `[ :a, :b ]` spacing inside array brackets (rails-omakase style)
  - Follow existing pattern: model validations + default_scope, shoulda-matchers for spec, factory with sequences
  - Always add association spec to both sides (belongs_to and has_many)
---

## 2026-02-16 - US-004
- Created PlantSubcategory model with: plant_category_id (FK, not null), name (string, not null), description, position
- Added composite unique index on [plant_category_id, name]
- Model validates name presence and uniqueness scoped to plant_category_id
- Default scope orders by position
- Added `has_many :plant_subcategories, dependent: :destroy` to PlantCategory
- Created factory and comprehensive model specs (associations, validations, scoped uniqueness, default scope, factory)
- Files changed:
  - `db/migrate/20260216234018_create_plant_subcategories.rb` (new)
  - `app/models/plant_subcategory.rb` (new)
  - `app/models/plant_category.rb` (updated — added has_many association)
  - `spec/models/plant_subcategory_spec.rb` (new)
  - `spec/models/plant_category_spec.rb` (updated — added association test)
  - `spec/factories/plant_subcategories.rb` (new)
  - `db/schema.rb` (auto-updated by migration)
- **Learnings for future iterations:**
  - Pattern is well-established: migration with null/unique constraints, model with belongs_to/validations/default_scope, factory with sequences, spec mirroring parent model spec structure
  - Each new taxonomy model follows the same template — future models (Plant, etc.) will differ more
---

## 2026-02-16 - US-005
- Created Plant model with: plant_category_id (FK, not null), plant_subcategory_id (FK, nullable), name (string, not null), latin_name, heirloom (boolean, default false), days_to_harvest_min, days_to_harvest_max, winter_hardy (enum), life_cycle (enum, not null), planting_seasons (string array), expected_viability_years, references_urls (text array), notes
- Enum definitions: winter_hardy (hardy/semi_hardy/tender), life_cycle (annual/biennial/perennial)
- belongs_to :plant_category, belongs_to :plant_subcategory (optional)
- Added `has_many :plants, dependent: :destroy` to both PlantCategory and PlantSubcategory
- Validates name and life_cycle presence
- Created factory and comprehensive model specs (associations, validations, enums, optional subcategory, defaults, factory)
- Files changed:
  - `db/migrate/20260216234254_create_plants.rb` (new)
  - `app/models/plant.rb` (new)
  - `app/models/plant_category.rb` (updated — added has_many :plants)
  - `app/models/plant_subcategory.rb` (updated — added has_many :plants)
  - `spec/models/plant_spec.rb` (new)
  - `spec/models/plant_category_spec.rb` (updated — added association test)
  - `spec/models/plant_subcategory_spec.rb` (updated — added association test)
  - `spec/factories/plants.rb` (new)
  - `db/schema.rb` (auto-updated by migration)
- **Learnings for future iterations:**
  - Named the column `references_urls` instead of `references` to avoid conflict with Rails' `references` method
  - PostgreSQL array columns: use `array: true, default: []` in migration
  - Enum columns use integer type in migration, `enum :field, { key: value }` in model
  - `optional: true` on belongs_to for nullable FK associations
  - Plant model is the first model that diverges from the taxonomy template — has enums, optional association, array columns
---

## 2026-02-16 - US-006
- Created SeedSource model with: name (string, unique, not null), url (string), notes (text), timestamps
- Added unique index on name
- Model validates name presence and uniqueness
- Created factory and comprehensive model specs (validations, factory uniqueness)
- Files changed:
  - `db/migrate/20260216234556_create_seed_sources.rb` (new)
  - `app/models/seed_source.rb` (new)
  - `spec/models/seed_source_spec.rb` (new)
  - `spec/factories/seed_sources.rb` (new)
  - `db/schema.rb` (auto-updated by migration)
- **Learnings for future iterations:**
  - SeedSource is a simple standalone model — no position ordering, no parent association
  - Future US-007 (SeedPurchase) will need `has_many :seed_purchases` added to this model
---
