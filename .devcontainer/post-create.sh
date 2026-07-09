#!/usr/bin/env bash
set -euo pipefail

echo "Installing gems..."
bundle check || bundle install

echo "Preparing databases..."
bin/rails db:prepare
bin/rails db:seed
RAILS_ENV=test bin/rails db:prepare

echo
echo "Ready. Start the app with:"
echo "  bin/rails server -b 0.0.0.0"
