require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  config.action_controller.perform_caching = false
  config.action_controller.enable_fragment_cache_logging = true

  config.action_dispatch.show_exceptions = :all

  config.active_support.deprecation = :log

  config.assets.debug = true if config.respond_to?(:assets)

  config.hosts.clear
end
