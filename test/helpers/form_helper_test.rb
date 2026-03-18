require "test_helper"

class FormHelperTest < ActionView::TestCase
  include HtmlHelper
  include AppendHelper
  include IconHelper
  include Heroicons::Helper
  include ButtonHelper
  include FormHelper

  # Stand-in model with validation support for testing error branches.
  class SampleModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :email, :string

    validates :name, presence: true
  end

  # --- FormHelper#sanitized_field_id ---

  test "sanitized_field_id: basic case" do
    assert_equal "user_name", send(:sanitized_field_id, "user", "name")
  end

  test "sanitized_field_id: brackets become underscores" do
    assert_equal "user_addresses_0_street",
                 send(:sanitized_field_id, "user[addresses][0]", "street")
  end

  # --- FormBuilder#extract_label ---

  test "extract_label returns humanized method name by default" do
    builder = make_builder
    assert_equal "First Name", builder.send(:extract_label, :first_name)
  end

  test "extract_label returns custom label from kwargs" do
    builder = make_builder
    opts = { label: "Custom" }
    assert_equal "Custom", builder.send(:extract_label, :name, opts)
    assert_empty opts
  end

  test "extract_label returns nil when label is false" do
    builder = make_builder
    opts = { label: false }
    assert_nil builder.send(:extract_label, :name, opts)
  end

  # --- FormBuilder#element_classes ---

  test "element_classes includes normal ring classes for clean model" do
    model = SampleModel.new(name: "Valid")
    builder = make_builder(model:)
    classes = builder.element_classes(:name).flatten
    assert_includes classes, "ring-zinc-300"
    refute_includes classes, "ring-danger-300"
  end

  test "element_classes includes danger ring classes when field has errors" do
    model = SampleModel.new
    model.validate
    builder = make_builder(model:)
    classes = builder.element_classes(:name).flatten
    assert_includes classes, "ring-danger-300"
    refute_includes classes, "ring-zinc-300"
  end

  test "element_classes handles non-model object without errors method" do
    builder = make_builder(model: false)
    classes = builder.element_classes(:name).flatten
    assert_includes classes, "ring-zinc-300"
    refute_includes classes, "ring-danger-300"
  end

  # --- FormBuilder#segmented_control ---

  test "segmented_control renders radio inputs for each choice" do
    model = SampleModel.new
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "Alpha", "a" ], [ "Beta", "b" ] ])

    assert_match %r{<input type="radio"[^>]*value="a"}, html
    assert_match %r{<input type="radio"[^>]*value="b"}, html
  end

  test "segmented_control marks the selected option as checked" do
    model = SampleModel.new(name: "b")
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "Alpha", "a" ], [ "Beta", "b" ] ])

    # The radio for "b" should be checked
    assert_match %r{value="b"[^>]*checked}, html
    # The radio for "a" should not be checked
    refute_match %r{value="a"[^>]*checked}, html
  end

  test "segmented_control renders option buttons with correct data-value" do
    model = SampleModel.new
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "Alpha", "a" ], [ "Beta", "b" ] ])

    assert_match %r{data-value="a"}, html
    assert_match %r{data-value="b"}, html
  end

  test "segmented_control renders label when provided" do
    model = SampleModel.new
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "A", "a" ] ], label: "Pick one")

    assert_match %r{Pick one}, html
  end

  test "segmented_control renders hint when provided" do
    model = SampleModel.new
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "A", "a" ] ], hint: "Choose wisely")

    assert_match %r{Choose wisely}, html
  end

  test "segmented_control renders errors when model has errors on the field" do
    model = SampleModel.new
    model.validate

    builder = make_builder(model:)
    html = builder.segmented_control(:name, [ [ "A", "a" ] ])

    assert_match %r{text-danger-600}, html
  end

  test "segmented_control uses default label from method name" do
    model = SampleModel.new
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "A", "a" ] ])

    assert_match %r{Name}, html
  end

  test "segmented_control omits label when label: false" do
    model = SampleModel.new
    builder = make_builder(model:)

    html = builder.segmented_control(:name, [ [ "A", "a" ] ], label: false)

    refute_match %r{<label}, html
  end

  # --- form_with error handling ---

  test "form_with renders error summary when model has errors" do
    model = SampleModel.new
    model.validate

    html = form_with(model:, url: "/test") do |f|
      f.text_field :name
    end

    assert_match /error_summary/, html
    assert_match /prohibited/, html
  end

  test "form_with omits error summary when model is clean" do
    model = SampleModel.new(name: "Valid")

    html = form_with(model:, url: "/test") do |f|
      f.text_field :name
    end

    refute_match /error_summary/, html
  end

  test "form_with preserves url and method when model has errors" do
    model = SampleModel.new
    model.validate

    html = form_with(model:, url: "/custom-path", method: :patch) do |f|
      f.text_field :name
    end

    assert_match %r{action="/custom-path"}, html
    assert_match /patch/i, html
  end

  test "form_with omits error summary without a block" do
    model = SampleModel.new
    model.validate

    html = form_with(model:, url: "/test")
    refute_match /error_summary/, html
  end

  private

  def make_builder(model: SampleModel.new(name: "ok"), object_name: "sample_model")
    ::FormHelper::FormBuilder.new(object_name, model, self, {})
  end
end
