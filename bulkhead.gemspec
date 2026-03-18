require_relative "lib/bulkhead/version"

Gem::Specification.new do |spec|
  spec.name        = "bulkhead"
  spec.version     = Bulkhead::VERSION
  spec.authors     = [ "iheartjane" ]
  spec.summary     = "Factory's reusable view layer — helpers, Stimulus controllers, Tailwind tokens, and shared partials."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib,vendor}/**/*", "Rakefile"]
  end

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "heroicons"
  spec.add_dependency "pagy"
  spec.add_dependency "commonmarker"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "stimulus-rails"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
end
