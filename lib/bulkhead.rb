require "bulkhead/version"
require "bulkhead/engine"

module Bulkhead
  mattr_accessor :kitchen_sink_layout, default: "application"
end
