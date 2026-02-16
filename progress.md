## Codebase Patterns
- Use `find_or_create_by!` in seeds for idempotent seed data
- Models use `default_scope { order(:position) }` for position-ordered records
- Factory sequences for unique fields: `sequence(:name) { |n| "Plant Type #{n}" }`
- Database constraints (null: false, unique index) should mirror model validations
---

## 2026-02-16 - US-002
- Implemented PlantType model with name (string, unique, not null), description (text), position (integer), timestamps
- Migration includes unique index on name column
- Model has presence/uniqueness validations and default_scope ordering by position
- Seed data: Vegetable, Grain, Herb, Flower, Cover Crop (idempotent via find_or_create_by!)
- Factory uses sequences for unique name generation
- 5 passing specs covering validations, ordering, and factory behavior
- Files changed:
  - db/migrate/20260216233522_create_plant_types.rb
  - app/models/plant_type.rb
  - db/seeds.rb
  - spec/models/plant_type_spec.rb
  - spec/factories/plant_types.rb
- **Learnings for future iterations:**
  - Rails 8.1.2 project with RSpec, FactoryBot, Shoulda Matchers, Faker all pre-configured
  - spec/support/shoulda_matchers.rb already set up
  - FactoryBot syntax methods already included in rails_helper.rb
  - Use `bin/rails generate model` to scaffold model, migration, spec, and factory together
---
