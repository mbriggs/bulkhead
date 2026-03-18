# Bulkhead engine — registers helpers, assets, and importmap pins.
# Tailwind class scanning is handled by tailwindcss-rails engine support
# via app/assets/tailwind/bulkhead/engine.css.
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
    # Stylesheets and vendor CSS for air-datepicker, plus JavaScript directories
    # for Stimulus controllers and vendor libs (dragula, air-datepicker JS).
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
