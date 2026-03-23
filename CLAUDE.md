# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

- **Ruby 4.0.2**, Rails 8.1
- **PostgreSQL** (primary database)
- **Solid Cache / Queue / Cable** — database-backed adapters (no Redis)
- **Propshaft** — asset pipeline
- **jsbundling-rails + cssbundling-rails** — JS/CSS bundling via Bun
- **Tailwind v4 + DaisyUI v5** — CSS framework (CSS-first config, no tailwind.config.js)
- **Hotwire** (Turbo + Stimulus)
- **Devise** — authentication (password-only now; OmniAuth-ready for Google/GitHub/Apple)
- **Kamal** — deployment via Docker

## Commands

```bash
# First-time setup (installs deps, prepares DB, starts server)
bin/setup

# Start development server (Rails + Tailwind CSS watcher via foreman)
bin/dev

# Build CSS once
bun run build:css

# Run all specs
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/models/user_spec.rb

# Run only request specs
bundle exec rspec spec/requests

# Run only system specs (browser tests via capybara-playwright-driver)
bundle exec rspec spec/system

# Lint
bin/rubocop

# Security scans
bin/brakeman --no-pager
bin/bundler-audit
```

## Testing Conventions

- **Request specs** (`spec/requests/`) — test controller actions and routing via HTTP. Preferred over controller specs.
- **System specs** (`spec/system/`) — full browser tests via capybara-playwright-driver; use `js: true` metadata to activate the Playwright driver.
- **Model specs** (`spec/models/`) — unit tests for models and validations.
- No controller specs (`spec/controllers/`).

## CI Pipeline

CI runs on PRs and pushes to `main` via GitHub Actions (`.github/workflows/ci.yml`):
1. `scan_ruby` — Brakeman static analysis + bundler-audit gem vulnerability scan
2. `lint` — RuboCop with `rubocop-rails-omakase` style (Rails omakase defaults, no customizations)
3. `test` — RSpec request + model specs against PostgreSQL
4. `system-test` — RSpec system specs via capybara-playwright-driver; screenshots of failures uploaded as artifacts

## Authentication

Devise is configured with `authenticate_user!` globally in `ApplicationController`. To allow unauthenticated access to specific actions:
```ruby
skip_before_action :authenticate_user!, only: [:index, :show]
```

OmniAuth (Google, GitHub, Apple) is not yet installed. See `config/initializers/devise.rb` and `app/models/user.rb` for the full setup checklist when ready to add it.

## Database

Development uses `calmendar_development`, test uses `calmendar_test`. No credentials needed locally — connects via domain socket as the OS user. Production uses separate databases for primary, cache, queue, and cable connections.

```bash
bin/rails db:prepare   # create + migrate (idempotent)
bin/rails db:reset     # drop + recreate + seed
bin/rails db:test:prepare
```
