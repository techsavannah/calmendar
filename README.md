# Calmendar

## Introduction

This is a beginning. As of this writing, it barely even _does_ anything, much less _stand_ for anything. It's a community effort to build a new place to join other people, whether in person or virtually, to do _stuff_.

We're [TechSAV](https://techsav.co), and we've been around for about a decade in Savannah, and this is the first time we've tried building software together, after building the tech community in Savannah, and building a _lot_ of events together.

We don't know where this is going, but we can't wait to find out!

### Joining in

We're not accepting outside help right now, but please try out the software! We're trying to build it _very_ quickly in our spare time using whatever means we can (which include AI, sorry, but we're very careful and professionals - every PR will require tests and we'll run security tests before unleashing it on the public).

If you're in Savannah and would like to join in the fun, hit up [the website](https://techsav.co) for more details or email [Kevin](https://techsav.co) with questions!

## Requirements

- Ruby 4.0.2 (managed via [mise](https://mise.jdx.dev))
- Node.js + Bun (managed via mise)
- PostgreSQL

## Setup

Install dependencies and prepare the database:

```bash
bin/setup
```

This installs Ruby gems, installs JS packages via Bun, and creates/migrates the database.

If you need to reset the database from scratch:

```bash
bin/setup --reset
```

## Development

Start the development server (Rails + Tailwind CSS watcher):

```bash
bin/dev
```

The app will be available at `http://localhost:3000`.

## Testing

```bash
bundle exec rspec                           # all specs
bundle exec rspec spec/requests             # request specs only
bundle exec rspec spec/system               # system (browser) specs
bundle exec rspec spec/models/user_spec.rb  # single file
```

System specs run against a real browser via [capybara-playwright-driver](https://github.com/YusukeIwaki/capybara-playwright-driver). On first run, install the Playwright browser:

```bash
bundle exec playwright install chromium
```

## Linting & Security

```bash
bin/rubocop          # Ruby style (rails-omakase defaults)
bin/brakeman         # Static security analysis
bin/bundler-audit    # Gem vulnerability scan
```

## Database

```bash
bin/rails db:prepare        # Create and migrate (idempotent)
bin/rails db:migrate        # Run pending migrations
bin/rails db:reset          # Drop, recreate, and seed
bin/rails db:test:prepare   # Prepare the test database
```

## Deployment

The app is deployed via [Kamal](https://kamal-deploy.org) as a Docker container.

```bash
kamal deploy
```
