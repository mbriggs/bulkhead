require "test_helper"

# Asserts that every tone the helpers emit has a matching CSS selector.
# Catches drift when a tone is added to Ruby but not the stylesheet (or
# vice versa). Reads each split component file once at load time.
class ToneCoverageTest < ActiveSupport::TestCase
  CSS_DIR = File.expand_path("../../app/assets/stylesheets/bulkhead", __dir__)
  ALL_CSS = Dir[File.join(CSS_DIR, "**/*.css")].map { |path| File.read(path) }.join("\n")

  COVERAGE = {
    "alert"        => %w[info success warning danger],
    "badge"        => %w[default primary danger success warning info purple high],
    "progress-bar" => %w[info primary success warning danger default],
    "button"       => %w[primary danger secondary]
  }.freeze

  COVERAGE.each do |component, tones|
    tones.each do |tone|
      test "#{component}.#{tone} has a CSS rule" do
        assert_match(/\.#{Regexp.escape(component)}\.#{Regexp.escape(tone)}\b/, ALL_CSS,
          "expected a `.#{component}.#{tone}` rule somewhere in app/assets/stylesheets/bulkhead/")
      end
    end
  end
end
