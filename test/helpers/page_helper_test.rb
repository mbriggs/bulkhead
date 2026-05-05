require "test_helper"

class PageHelperTest < ActionView::TestCase
  include HtmlHelper
  include PageHelper

  test "page_separator renders hr tag" do
    html = page_separator
    assert_match(/<hr/, html)
    assert_match(/separator/, html)
  end

  test "page_separator visible false omits border color classes" do
    html = page_separator(visible: false)
    assert_match(/<hr/, html)
    assert_match(/borderless/, html)
  end

  test "section_head renders uppercase title with optional meta" do
    html = section_head("Last 24 hours", meta: "5 finished")
    assert_match(%r{<div class="section-head">}, html)
    assert_match(%r{<h3 class="section-title">Last 24 hours</h3>}, html)
    assert_match(%r{<p class="section-meta">5 finished</p>}, html)
  end

  test "section_head omits meta line when meta is nil" do
    html = section_head("In flight")
    assert_match(%r{<h3 class="section-title">In flight</h3>}, html)
    refute_match(/section-meta/, html)
  end

  test "pill_nav renders counted active filter links" do
    html = pill_nav([
      { label: "All", href: "/jobs", count: 3, active: true },
      { label: "Failed", href: "/jobs?status=failed", count: 1 }
    ], label: "Job filters")

    assert_match(/<nav class="pill-nav" aria-label="Job filters">/, html)
    assert_match(/class="pill-nav-item active" aria-current="page"/, html)
    assert_match(/class="pill-nav-count">3<\/span>/, html)
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
