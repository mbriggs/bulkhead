require_relative "boot"

require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"

require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"
require "heroicons"
require "pagy"
require "commonmarker"
require "bulkhead"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "bulkhead-dummy-app-development-secret-key-do-not-use-in-production"
  end
end
