require "test_helper"

class CardHelperTest < ActionView::TestCase
  include HtmlHelper
  include CardHelper

  test "card_classes returns base classes with shadow" do
    classes = card_classes
    assert_includes classes, "bg-white"
    assert_includes classes, "rounded-lg"
    assert_includes classes, "border"
    assert_includes classes, "shadow-sm"
  end

  test "card_classes without shadow omits shadow-sm" do
    classes = card_classes(shadow: false)
    assert_includes classes, "bg-white"
    assert_includes classes, "rounded-lg"
    refute_includes classes, "shadow-sm"
  end

  test "panel_classes returns border-only classes" do
    classes = panel_classes
    assert_includes classes, "rounded-lg"
    assert_includes classes, "border"
    assert_includes classes, "overflow-hidden"
    refute_includes classes, "bg-white"
    refute_includes classes, "shadow-sm"
  end

  test "panel_classes with visible overflow" do
    classes = panel_classes(overflow: :visible)
    assert_includes classes, "overflow-visible"
    refute_includes classes, "overflow-hidden"
  end

  test "inset_classes returns accent-stripe classes" do
    classes = inset_classes
    assert_includes classes, "bg-zinc-50"
    assert_includes classes, "border-l-2"
    assert_includes classes, "border-zinc-300"
  end

  test "inset_classes accepts extra classes" do
    classes = inset_classes("p-4")
    assert_includes classes, "p-4"
    assert_includes classes, "bg-zinc-50"
  end

  test "card_header with title only renders h3 without subtitle" do
    html = card_header("Title")
    assert_match /<h3.*>Title<\/h3>/, html
    refute_match /<p/, html
  end

  test "card_header with subtitle renders h3 and p" do
    html = card_header("Title", "Subtitle text")
    assert_match /<h3.*>Title<\/h3>/, html
    assert_match /<p.*>Subtitle text<\/p>/, html
  end
end
