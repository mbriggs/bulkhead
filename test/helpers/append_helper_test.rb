require "test_helper"

class AppendHelperTest < ActionView::TestCase
  include HtmlHelper
  include AppendHelper

  test "adds controller when none exists" do
    kwargs = { data: {} }
    append_controller!("modal", kwargs)
    assert_equal "modal", kwargs[:data][:controller]
  end

  test "merges with existing string controller" do
    kwargs = { data: { controller: "toggle" } }
    append_controller!("modal", kwargs)
    assert_equal [ "toggle", "modal" ], kwargs[:data][:controller]
  end

  test "merges with existing array controller" do
    kwargs = { data: { controller: [ "toggle", "dropdown" ] } }
    append_controller!("modal", kwargs)
    assert_equal [ "toggle", "dropdown", "modal" ], kwargs[:data][:controller]
  end

  test "append_confirm! sets turbo_confirm and disables prefetch" do
    kwargs = { data: {} }
    append_confirm!(kwargs, "Are you sure?")
    assert_equal "Are you sure?", kwargs[:data][:turbo_confirm]
    assert_equal "false", kwargs[:data]["turbo_prefetch"]
  end

  test "append_confirm! no-ops when confirm is falsy" do
    kwargs = { data: {} }
    append_confirm!(kwargs, nil)
    refute kwargs[:data].key?(:turbo_confirm)

    append_confirm!(kwargs, false)
    refute kwargs[:data].key?(:turbo_confirm)
  end
end
