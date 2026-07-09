source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.2"

gem "rails", "~> 8.1", ">= 8.1.3"
gem "rails-i18n", "~> 8.1"
gem "sprockets-rails"
gem "dartsass-sprockets"
gem "pg", "~> 1.6", force_ruby_platform: true
gem "puma", ">= 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "bootstrap", "~> 5.3"
gem "bootstrap_form", "~> 5.0"
gem "bootstrap-icons-helper"
gem "devise"
gem "devise-i18n"
gem "holidays"
gem "pundit"
gem "roo"
gem "roo-xls"
gem "rufus-scheduler"
gem "rexml"

group :development, :test do
  gem "debug"
  gem "minitest", "< 6"
end

group :development do
  gem "web-console", ">= 4.1.0"
  gem "rack-mini-profiler", ">= 2.0"
end

group :test do
  gem "capybara", ">= 3.26"
  gem "selenium-webdriver"
end
