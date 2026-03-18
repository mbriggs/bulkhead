require "test_helper"

class TableHelperTest < ActionView::TestCase
  include HtmlHelper
  include IconHelper
  include Heroicons::Helper
  include TableHelper

  test "sort_field returns plain title when sortable is false" do
    result = sort_field(:name, sortable: false)
    assert_equal "Name", result
  end

  test "sort_field generates link defaulting to descending" do
    @controller.request.env["QUERY_STRING"] = ""
    html = sort_field(:name, namespace: nil)
    assert_match /<a/, html
    assert_includes html, "sort=name"
    assert_includes html, "sort_order=d"
  end

  test "sort_field toggles to ascending when currently descending" do
    @controller.request.env["QUERY_STRING"] = "sort=name&sort_order=d"
    html = sort_field(:name, namespace: nil)
    assert_includes html, "sort_order=a"
    assert_match /svg/, html
  end

  test "sort_field nests params under namespace" do
    @controller.request.env["QUERY_STRING"] = ""
    html = sort_field(:name, namespace: :filter)
    assert_includes html, "filter%5Bsort%5D=name"
    assert_includes html, "filter%5Bsort_order%5D=d"
  end

  private

  # Bypass routing — we're testing param logic, not Rails routing
  def url_for(options = {})
    return options.to_s unless options.is_a?(Hash)
    "/?#{options.to_query}"
  end
end
