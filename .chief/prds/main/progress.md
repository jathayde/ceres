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
