require "test_helper"

class HtmlHelperTest < ActionView::TestCase
  include HtmlHelper

  test "string args joined with spaces" do
    assert_equal "foo bar", classnames("foo", "bar")
  end

  test "hash args include truthy, exclude falsy" do
    result = classnames("base", { "active" => true, "hidden" => false })
    assert_includes result, "active"
    refute_includes result, "hidden"
  end

  test "nested arrays are flattened" do
    result = classnames("a", [ "b", [ "c" ] ])
    assert_includes result, "a"
    assert_includes result, "b"
    assert_includes result, "c"
  end

  test "duplicate classes are removed" do
    result = classnames("foo", "bar", "foo")
    assert_equal "foo bar", result
  end

  # --- default_class ---

  test "default_class returns default when value is nil" do
    assert_equal "max-w-prose", default_class(nil, "max-w-prose")
  end

  test "default_class returns custom value when provided" do
    assert_equal "max-w-lg", default_class("max-w-lg", "max-w-prose")
  end

  test "default_class returns nil when value is false" do
    assert_nil default_class(false, "max-w-prose")
  end
end
