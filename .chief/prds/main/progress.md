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
