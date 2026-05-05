require "test_helper"

class CardHelperTest < ActionView::TestCase
  include HtmlHelper
  include CardHelper

  test "card_classes returns base classes with shadow" do
    classes = card_classes
    assert_includes classes, "card"
    assert_includes classes, "shadow"
  end

  test "card_classes without shadow omits shadow modifier" do
    classes = card_classes(shadow: false)
    assert_includes classes, "card"
    refute_includes classes, "shadow"
  end

  test "panel_classes returns border-only classes" do
    classes = panel_classes
    assert_includes classes, "panel"
    assert_includes classes.split, "clipped"
    refute_includes classes, "card"
    refute_includes classes, "shadow"
  end

  test "panel_classes with visible overflow" do
    classes = panel_classes(overflow: :visible)
    assert_includes classes.split, "unclipped"
    refute_includes classes.split, "clipped"
  end

  test "inset_classes returns accent-stripe classes" do
    classes = inset_classes
    assert_includes classes, "inset"
  end

  test "inset_classes accepts extra classes" do
    classes = inset_classes("padded")
    assert_includes classes, "padded"
    assert_includes classes, "inset"
  end

  test "card_header with title only renders h3 without subtitle" do
    html = card_header("Title")
    assert_match(/<h3.*>Title<\/h3>/, html)
    refute_match(/<p/, html)
  end

  test "card_header with subtitle renders h3 and p" do
    html = card_header("Title", "Subtitle text")
    assert_match(/<h3.*>Title<\/h3>/, html)
    assert_match(/<p.*>Subtitle text<\/p>/, html)
  end

  test "card region helpers render shared card part classes" do
    assert_match(/class="card-body extra"/, card_body(classes: "extra") { "Body" })
    assert_match(/class="card-section"/, card_section { "Section" })
    assert_match(/class="card-footer"/, card_footer { "Footer" })
  end
end
