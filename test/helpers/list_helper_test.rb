require "test_helper"

class ListHelperTest < ActionView::TestCase
  include ListHelper

  test "item_list returns nil for blank collection" do
    assert_nil item_list([]) { |_i, _item| }
  end

  test "badge_color_classes returns specific colors for known types" do
    classes = badge_color_classes(:green)
    assert_includes classes, "bg-green-50"
    assert_includes classes, "text-green-700"
  end

  test "badge_color_classes returns default zinc for unknown types" do
    classes = badge_color_classes(:nonexistent)
    assert_includes classes, "bg-zinc-50"
    assert_includes classes, "text-zinc-600"
  end
end
