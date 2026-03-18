require "test_helper"

class ButtonHelperTest < ActionView::TestCase
  include HtmlHelper
  include AppendHelper
  include IconHelper
  include Heroicons::Helper

  test "url renders a link, no url renders a button" do
    assert_match /<button/, button("Save", type: :primary)
    assert_match /<a/, button("Go", type: :secondary, url: "/somewhere")
  end

  test "solid button icons are white, non-solid icons are zinc" do
    assert_match /text-white\/80/, button("Create", type: :primary, icon_name: :plus)
    assert_match /text-zinc-400/, button("Edit", type: :secondary, icon_name: :pencil)
  end

  test "confirm wires up turbo-confirm data attribute" do
    assert_match /data-turbo-confirm/, button("Delete", type: :danger, confirm: "Sure?")
  end

  test "modal flag wires up modal action" do
    assert_match /modal#open/, button("Open", type: :primary, modal: true)
  end

  test "link method converts to turbo-method, get is excluded" do
    assert_match /data-turbo-method="delete"/, button("Delete", type: :danger, url: "/x", method: :delete)
    refute_match /turbo-method/, button("View", type: :secondary, url: "/x", method: :get)
  end

  test "shadow false omits shadow classes" do
    classes = button_classes(type: :primary, shadow: false)
    refute_includes classes, "shadow-sm"
    assert_includes classes, "font-semibold"
  end

  test "shadow true includes shadow classes by default" do
    classes = button_classes(type: :primary)
    assert_includes classes, "shadow-sm"
  end
end
