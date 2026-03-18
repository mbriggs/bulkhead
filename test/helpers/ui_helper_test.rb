require "test_helper"

class UiHelperTest < ActionView::TestCase
  include HtmlHelper
  include IconHelper
  include Heroicons::Helper
  include UiHelper

  test "status_badge active uses success colors" do
    html = status_badge(true)
    assert_match /Active/, html
    assert_match /bg-success-100/, html
  end

  test "status_badge inactive uses zinc colors" do
    html = status_badge(false)
    assert_match /Inactive/, html
    assert_match /bg-zinc-100/, html
  end

  test "status_badge text style uses text-only classes" do
    html = status_badge(true, style: :text)
    assert_match /text-success-600/, html
    refute_match /rounded-full/, html
  end

  test "status_badge custom labels with boolean keys" do
    html = status_badge(true, labels: { true => "On", false => "Off" })
    assert_match /On/, html
  end

  # -- badge --

  test "badge accepts a block for rich content" do
    html = badge(colors: "bg-blue-100 text-blue-700") { "inner content" }
    assert_match /rounded-full/, html
    assert_match /inner content/, html
    assert_match /bg-blue-100/, html
  end

  # -- removable_badge --

  test "removable_badge renders text with a delete button" do
    html = removable_badge("Tag", remove_path: "/remove/1", colors: "bg-red-100 text-red-700")
    assert_match /Tag/, html
    assert_match /action="\/remove\/1"/, html
    assert_match /method/, html
  end

  test "loading_skeleton with no title and 3 rows" do
    html = loading_skeleton(rows: 3, title: false)
    assert_match /animate-pulse/, html
    refute_match /h-8/, html
    assert_equal 3, html.scan(/h-10/).length
  end

  # -- safe_url --

  test "safe_url allows http URLs" do
    assert_equal "http://example.com", safe_url("http://example.com")
  end

  test "safe_url allows https URLs" do
    assert_equal "https://example.com/path?q=1", safe_url("https://example.com/path?q=1")
  end

  test "safe_url allows mailto URLs" do
    assert_equal "mailto:user@example.com", safe_url("mailto:user@example.com")
  end

  test "safe_url blocks javascript URLs" do
    assert_nil safe_url("javascript:alert('xss')")
  end

  test "safe_url blocks javascript URLs with mixed case" do
    assert_nil safe_url("JavaScript:alert(1)")
  end

  test "safe_url blocks data URLs" do
    assert_nil safe_url("data:text/html,<script>alert(1)</script>")
  end

  test "safe_url blocks vbscript URLs" do
    assert_nil safe_url("vbscript:MsgBox")
  end

  test "safe_url allows schemeless relative URLs" do
    assert_equal "/path/to/page", safe_url("/path/to/page")
  end

  test "safe_url returns nil for blank input" do
    assert_nil safe_url("")
    assert_nil safe_url(nil)
  end

  test "safe_url returns nil for malformed URIs" do
    assert_nil safe_url("ht tp://bad url")
  end

  test "safe_url strips whitespace and null bytes" do
    assert_equal "https://example.com", safe_url("  https://example.com  ")
    assert_equal "https://example.com", safe_url("https://\x00example.com")
  end

  test "safe_url strips embedded newlines and tabs" do
    assert_equal "https://example.com", safe_url("https://\nexample.com")
    assert_equal "https://example.com", safe_url("https://\texample.com")
  end
end
