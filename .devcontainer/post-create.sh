#!/usr/bin/env bash
set -euo pipefail

echo "Installing gems..."
bundle check || bundle install

echo "Preparing databases..."
bin/rails db:create
bin/rails db:environment:set RAILS_ENV=development
bin/rails db:schema:load
RAILS_ENV=test bin/rails db:environment:set
RAILS_ENV=test bin/rails db:schema:load

echo
echo "Ready. Start the app with:"
echo "  bin/rails server -b 0.0.0.0"
