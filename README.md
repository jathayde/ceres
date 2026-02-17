# Ceres

Ceres is a single-user seed inventory and reference application. It replaces a sprawling Excel spreadsheet for managing a personal seed collection of 650+ varieties across vegetables, grains, herbs, flowers, and cover crops.

Ceres tracks what seeds you have, where they came from, whether they're still viable, and how to grow them. It is not a planting journal or garden planner — it's the reference library and inventory system.

## Features

- **Three-level plant taxonomy** — organize seeds by type (Vegetable, Grain, Herb, etc.), category (Tomato, Bean, Pepper), and optional subcategory (Bush Bean, Pole Bean)
- **Seed purchase tracking** — record supplier, year purchased, quantity, cost, lot number, and reorder URL for every seed lot
- **Viability monitoring** — automatic seed age calculations with viable/test/expired status based on expected viability years per crop type
- **Viability audit dashboard** — filter and review aging seed inventory with bulk mark-as-used-up actions
- **Full-text search** — search across plant names, Latin names, notes, seed sources, and categories via PostgreSQL
- **Inventory browser** — hierarchical sidebar navigation through the full taxonomy tree
- **Spreadsheet import** — upload an Excel file and walk through a multi-stage workflow: parse, AI-assisted mapping to taxonomy, review, confirm, and bulk execute
- **AI-powered enrichment** — generate growing guides, look up Latin names, and estimate viability years using the Anthropic Claude API
- **Seed source management** — track suppliers with merge support to consolidate duplicates

## Requirements

- Ruby 3.4.8
- PostgreSQL 16+
- Node.js (for Tailwind CSS compilation)

## Setup

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd ceres
bundle install
```

### 2. Configure the Anthropic API key

AI features (growing guides, Latin name lookup, spreadsheet mapping, viability enrichment) require an [Anthropic API key](https://console.anthropic.com/). The app works without one — AI features will simply fail gracefully — but to enable them, choose one of these methods:

**Option A: Environment variable (recommended for development)**

Create a `.env` file in the project root (it is gitignored):

```bash
echo 'ANTHROPIC_API_KEY=your-key-here' > .env
```

Then source it before starting the server, or use a tool like [dotenv](https://github.com/bkeepers/dotenv).

Alternatively, export it directly in your shell:

```bash
export ANTHROPIC_API_KEY=your-key-here
```

**Option B: Rails encrypted credentials**

```bash
bin/rails credentials:edit
```

Add the following YAML:

```yaml
anthropic:
  api_key: your-key-here
```

The app checks `ENV["ANTHROPIC_API_KEY"]` first, then falls back to Rails credentials.

### 3. Create and seed the database

```bash
bin/rails db:create db:migrate db:seed
```

Seed data populates the plant type and category taxonomy (Vegetable, Grain, Herb, Flower, Cover Crop and their subcategories with Latin names and expected viability years).

### 4. Start the development server

```bash
foreman start -f Procfile.dev
```

This starts both the Rails server and the Tailwind CSS watcher. The app will be available at [http://localhost:3000](http://localhost:3000).

If you don't have foreman, you can run each process separately:

```bash
bin/rails server
bin/rails tailwindcss:watch  # in a separate terminal
```

## Running tests

```bash
bin/rspec                           # all specs
bin/rspec spec/models/              # model specs
bin/rspec spec/requests/            # request specs
bin/rspec spec/requests/workflows/  # workflow integration tests
bin/rspec spec/path/to_spec.rb:42   # single example by line number
```

## Linting and security

```bash
bin/rubocop                # code style (Rails Omakase)
bin/brakeman --no-pager    # security vulnerability scan
bin/bundler-audit           # gem vulnerability check
bin/importmap audit         # JS dependency audit
```

## Tech stack

- **Framework:** Rails 8.1 with Hotwire (Turbo + Stimulus)
- **Database:** PostgreSQL with pg_search for full-text search
- **Background jobs:** Solid Queue
- **Frontend:** Tailwind CSS, ViewComponent, Stimulus controllers, Turbo Frames
- **Asset pipeline:** PropShaft + Importmap
- **AI:** Anthropic Claude API (via the `anthropic` gem)
- **Testing:** RSpec, FactoryBot, Shoulda Matchers, Capybara

## Docker

```bash
docker build -t ceres .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  -e ANTHROPIC_API_KEY=your-key-here \
  --name ceres ceres
```

## License

All rights reserved.
