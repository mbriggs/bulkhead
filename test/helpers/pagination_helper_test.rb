require "test_helper"

class PaginationHelperTest < ActionView::TestCase
  include HtmlHelper
  include PaginationHelper

  PagyStub = Struct.new(:count, keyword_init: true)

  test "pagination_info renders count and entity name" do
    pagy = PagyStub.new(count: 42)
    html = pagination_info(pagy, "items")
    assert_match /42/, html
    assert_match /items found/, html
  end

  test "pagination_info returns nil for nil pagy" do
    assert_nil pagination_info(nil, "items")
  end

  test "pagination_info accepts a Class and pluralizes the model name" do
    pagy = PagyStub.new(count: 5)
    klass = Class.new { def self.name = "Problem" }
    html = pagination_info(pagy, klass)
    assert_match /5/, html
    assert_match /problems found/, html
  end
end
