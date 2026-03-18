require "test_helper"

class AlertsHelperTest < ActionView::TestCase
  include HtmlHelper
  include IconHelper
  include Heroicons::Helper
  include AlertsHelper
  include UiHelper

  test "notice alert uses info color classes" do
    html = notice_alert("Watch out")
    assert_match /bg-info-50/, html
    assert_match /Watch out/, html
  end

  test "success alert uses success color classes" do
    html = success_alert("Done")
    assert_match /bg-success-50/, html
  end

  test "error alert uses danger color classes" do
    html = error_alert("Failed")
    assert_match /bg-danger-50/, html
  end


  test "string content wraps in p tag" do
    html = success_alert("Done", "All good")
    assert_match /<p>All good<\/p>/, html
  end

  test "hash content sanitizes and renders html" do
    html = success_alert("Done", { html: "<strong>bold</strong>" })
    assert_match /<strong>bold<\/strong>/, html
    assert_match /<p>/, html
  end

  test "array content renders as ul with li items" do
    html = error_alert("Errors", [ "First", "Second" ])
    assert_match /<ul/, html
    assert_match /<li>First<\/li>/, html
    assert_match /<li>Second<\/li>/, html
  end
end
