# Carteiras

## About This Project

Carteiras is a personal Rails application I built and used between 2020 and 2023 to track investment portfolios for myself and close family members. It was created as a practical tool for consolidating brokerage activity, cash balances, portfolio positions, dividends, taxes, and performance across different accounts and asset classes.

This was not built as a commercial product or professional financial platform. It was a long-running personal software project: useful enough to support real financial tracking workflows, but developed primarily for my own needs, with the tradeoffs and rough edges that come from a tool built incrementally over several years.

The application includes features for registering assets, brokers, portfolios, operations, cash movements, dividends and other proceeds; importing brokerage statements; calculating current positions and historical profitability; comparing portfolio allocation against reference targets; fetching market prices from external sources; and supporting tax-related views for investment operations.

The public version of this repository has been sanitized to remove private financial data, credentials, and personal statement fixtures.

## Development Container

This repository includes a Dev Container for the current Rails setup. It runs Ruby `4.0.2`, Rails `8.1.x`, PostgreSQL `18.4`, Chromium/Chromedriver for system tests, native build dependencies, and bundled gems inside a Docker volume.

Open the repository in a Dev Container-compatible editor and let the `postCreateCommand` run. The setup loads `db/schema.rb` directly instead of replaying the legacy migrations. Then start Rails from inside the container:

```sh
bin/rails server -b 0.0.0.0
```

The app is forwarded on port `3000`. PostgreSQL runs as service `db` with user/password `carteiras`. The database is rebuilt from `db/schema.rb` inside the dev container.

Useful verification commands inside the container:

```sh
bin/rails zeitwerk:check
bin/rails test
bin/rails test:system
```
