# Bulkhead engine importmap — merged into the host app's importmap by the engine initializer.
# Controllers are pinned under "controllers" so eagerLoadControllersFrom discovers them.
# The `to:` values are logical asset paths resolved by Propshaft from the registered
# asset directories (app/javascript, vendor/javascript).

pin_all_from Bulkhead::Engine.root.join("app/javascript/controllers"), under: "controllers"
pin_all_from Bulkhead::Engine.root.join("app/javascript/lib"), under: "lib"
pin "dragula", to: "dragula.js"
pin "air-datepicker", to: "air-datepicker.js"
