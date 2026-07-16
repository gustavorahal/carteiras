# Repository instructions

## Canonical development environment

- Use the Dev Container in `.devcontainer/` for development, database migrations, tests, and Rails commands.
- PostgreSQL runs in the Compose service `db`. Do not install or start PostgreSQL directly on the host unless the user explicitly requests it.
- From the host, run non-interactive agent commands with `docker compose -f .devcontainer/docker-compose.yml exec -T app ...` after starting the stack with `docker compose -f .devcontainer/docker-compose.yml up -d --build`.
- Keep the Ruby version aligned in `.ruby-version`, `Gemfile`, `Gemfile.lock`, and `.devcontainer/Dockerfile`.

## Environment discovery lesson

- Hidden directories are part of the repository architecture. Before changing host dependencies or creating new infrastructure, inspect them with commands that include hidden paths, such as `rg --hidden --files`, `find`, or `ls -la`.
- Check `.devcontainer/`, Docker Compose files, and existing project documentation before installing persistent services on the host.

## Required validation

Run these inside the `app` service after environment or application changes:

```sh
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
bin/rails zeitwerk:check
bin/rails test
```
