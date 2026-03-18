require "test_helper"

class PageHelperTest < ActionView::TestCase
  include HtmlHelper
  include PageHelper

  test "page_separator renders hr tag" do
    html = page_separator
    assert_match /<hr/, html
    assert_match /border-zinc-900/, html
  end

  test "page_separator visible false omits border color classes" do
    html = page_separator(visible: false)
    assert_match /<hr/, html
    assert_match /border-0/, html
    refute_match /border-zinc-900/, html
  end

  test "custom appends html to custom_entries in to_state" do
    builder = PageHelper::PageHeaderBuilder.new
    builder.custom("<span>hello</span>".html_safe)
    builder.custom("<span>world</span>".html_safe)

    _b, _p, _a, _d, _dd, custom_entries, _rm = builder.to_state

    assert_equal 2, custom_entries.size
    assert_includes custom_entries[0], "hello"
    assert_includes custom_entries[1], "world"
  end

  test "reader_mode stores entry with name title and block in to_state" do
    builder = PageHelper::PageHeaderBuilder.new
    block = -> { "content" }
    builder.reader_mode("Prompt", title: "Full Prompt", &block)

    _b, _p, _a, _d, _dd, _custom, reader_mode_entries = builder.to_state

    assert_equal 1, reader_mode_entries.size
    entry = reader_mode_entries.first
    assert_equal "Prompt", entry[:name]
    assert_equal "Full Prompt", entry[:title]
    assert_equal block, entry[:block]
  end
end
