require "test_helper"

class IconHelperTest < ActionView::TestCase
  include HtmlHelper
  include IconHelper
  include UiHelper
  include Heroicons::Helper

  test "icon converts underscores to hyphens" do
    html = icon(:check_circle)
    # The heroicons gem receives "check-circle" (hyphenated)
    assert_match /svg/, html
  end

  test "icon_link_to without tooltip renders plain link" do
    html = icon_link_to(:pencil, "/edit")
    assert_match /<a/, html
    assert_match /href="\/edit"/, html
    refute_match /group/, html
  end

  test "icon_link_to with tooltip renders link with tooltip wrapper" do
    html = icon_link_to(:pencil, "/edit", tooltip_text: "Edit")
    assert_match /<a/, html
    assert_match /group/, html
    assert_match /Edit/, html
  end
end
