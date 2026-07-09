# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Sass sources are inputs for dartsass-rails; Propshaft should publish only compiled builds.
sass_load_paths = [
  Rails.root.join("app/assets/stylesheets"),
  Pathname.new(Gem.loaded_specs.fetch("bootstrap").full_gem_path).join("assets/stylesheets")
]

Rails.application.config.assets.excluded_paths += sass_load_paths
Rails.application.config.dartsass.build_options << "--quiet-deps"
Rails.application.config.dartsass.build_options += sass_load_paths.map { |path| "--load-path=#{path}" }
