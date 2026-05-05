# Bulkhead engine — registers helpers, static assets, and importmap pins.

# IconHelper#icon delegates to `heroicon`, which the heroicons gem only
# attaches to ActionView when its engine boots. heroicons is a transitive
# dep of bulkhead but Bundler does not auto-require transitives, so host
# apps would otherwise see `undefined method 'heroicon'` until they
# require the gem themselves. Pull it in here so installs Just Work.
require "heroicons"

module Bulkhead
  class Engine < ::Rails::Engine
    engine_name "bulkhead"

    # --- Importmap merging ---
    # Append the gem's importmap config so Stimulus controllers are discovered
    # alongside the host app's controllers. Register cache sweepers so changes
    # to engine JS files trigger importmap recompilation in development.
    initializer "bulkhead.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << Engine.root.join("app/javascript")
      end
    end

    # --- Propshaft asset paths ---
    # Register all asset directories so Propshaft can find and serve them.
    # Bulkhead's static CSS, vendor CSS for air-datepicker, plus JavaScript
    # directories for Stimulus controllers and vendor libs.
    initializer "bulkhead.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << Engine.root.join("app/assets/stylesheets")
        app.config.assets.paths << Engine.root.join("app/javascript")
        app.config.assets.paths << Engine.root.join("vendor/assets/stylesheets")
        app.config.assets.paths << Engine.root.join("vendor/javascript")
      end
    end
  end
end
