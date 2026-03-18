require "test_helper"

class ModalHelperTest < ActionView::TestCase
  include HtmlHelper
  include ModalHelper

  test "modal_content_id appends -content to modal id" do
    assert_equal "my-modal-content", modal_content_id("my-modal")
  end

  test "modal_open_button renders button with modal#open action" do
    html = modal_open_button("Click me")
    assert_match /<button/, html
    # The > in Stimulus action is HTML-entity-encoded in attributes
    assert_includes html, "click-&gt;modal#open"
    assert_match /Click me/, html
  end

  test "modal_wrapper renders div with modal controller" do
    html = modal_wrapper { tag.span("inner") }
    assert_match /data-controller="modal"/, html
    assert_match /inner/, html
  end

  test "modal_size_class maps size symbols to max-width classes" do
    assert_equal "max-w-lg", send(:modal_size_class, :md)
    assert_equal "max-w-3xl", send(:modal_size_class, :wide)
    assert_includes send(:modal_size_class, :full), "max-w-[90vw]"
  end

  test "modal_dialog raises when given both partial and block" do
    assert_raises(ArgumentError) do
      modal_dialog(id: "test", title: "Test", partial: "shared/modals/chrome") { "content" }
    end
  end
end
