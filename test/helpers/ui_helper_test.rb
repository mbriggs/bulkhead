require "test_helper"

class UiHelperTest < ActionView::TestCase
  include HtmlHelper
  include IconHelper
  include Heroicons::Helper
  include UiHelper

  test "status_badge active uses success colors" do
    html = status_badge(true)
    assert_match(/Active/, html)
    assert_match(/class="[^"]*\bbadge\b[^"]*\bsuccess\b/, html)
  end

  test "status_badge inactive uses zinc colors" do
    html = status_badge(false)
    assert_match(/Inactive/, html)
    assert_match(/class="[^"]*\bbadge\b[^"]*\bdefault\b/, html)
  end

  test "status_badge text style uses text-only classes" do
    html = status_badge(true, style: :text)
    assert_match(/class="[^"]*\bstatus-text\b[^"]*\bactive\b/, html)
    refute_match(/\bbadge\b/, html)
  end

  test "status_badge custom labels with boolean keys" do
    html = status_badge(true, labels: { true => "On", false => "Off" })
    assert_match(/On/, html)
  end

  # -- badge --

  test "badge accepts a block for rich content" do
    html = badge(colors: "info") { "inner content" }
    assert_match(/pill/, html)
    assert_match(/inner content/, html)
    assert_match(/class="[^"]*\bbadge\b[^"]*\binfo\b/, html)
  end

  test "progress_bar renders ARIA progress with tone size and CSS variable" do
    html = progress_bar(3, total: 4, tone: :success, size: :sm)

    assert_match(/role="progressbar"/, html)
    assert_match(/aria-valuenow="3"/, html)
    assert_match(/class="progress sm"/, html)
    assert_match(/class="progress-bar success"/, html)
    assert_match(/--progress-value: 75%/, html)
  end

  test "status_dot renders tone and pulse modifiers" do
    html = status_dot(tone: :warning, pulse: true)

    assert_match(/class="status-dot warning pulse"/, html)
    assert_match(/aria-hidden="true"/, html)
  end

  test "metric_grid renders definition list metrics" do
    html = metric_grid([["Done", 4, "success"]])

    assert_match(/<dl class="metric-grid">/, html)
    assert_match(/class="metric success"/, html)
    assert_match(/<dt>Done<\/dt>/, html)
    assert_match(/<dd>4<\/dd>/, html)
  end

  # -- removable_badge --

  test "removable_badge renders text with a delete button" do
    html = removable_badge("Tag", remove_path: "/remove/1", colors: "danger")
    assert_match(/Tag/, html)
    assert_match(/action="\/remove\/1"/, html)
    assert_match(/method/, html)
  end

  test "loading_skeleton with no title and 3 rows" do
    html = loading_skeleton(rows: 3, title: false)
    assert_match(/skeleton/, html)
    refute_match(/skeleton-title/, html)
    assert_equal 3, html.scan(/class="skeleton-row"/).length
  end

  test "truncated_text uses static line clamp class with a CSS variable" do
    html = truncated_text("Long text", lines: 7)

    assert_match(/line-clamp/, html)
    refute_match(/line-clamp-7/, html)
    assert_match(/--bulkhead-line-clamp: 7/, html)
  end

  test "render_markdown preserves safe GitHub-flavored markdown attributes" do
    html = render_markdown(<<~MARKDOWN)
      [Bulkhead](https://example.com "Docs")

      | Name | Value |
      | ---- | :---: |
      | One | Two |

      - [x] Done
    MARKDOWN

    assert_match(/href="https:\/\/example.com"/, html)
    assert_match(/title="Docs"/, html)
    assert_match(/align="center"/, html)
    assert_match(/type="checkbox"/, html)
    assert_match(/\bchecked(?:="checked"|="")?\b/, html)
    assert_match(/\bdisabled(?:="disabled"|="")?\b/, html)
  end

  test "render_markdown emits class based syntax highlighting" do
    html = render_markdown(<<~MARKDOWN)
      ```ruby
      class Demo
      end
      ```
    MARKDOWN

    assert_match(/<pre class="syntax-highlighting">/, html)
    assert_match(/class="[^"]*\bkeyword\b[^"]*\bcontrol\b/, html)
    assert_match(/data-controller="code-block-copy"/, html)
    refute_match(/style="/, html)
  end

  test "render_markdown removes unsafe markdown URLs" do
    html = render_markdown("[x](javascript:alert(1))")

    refute_match(/javascript:/, html)
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
