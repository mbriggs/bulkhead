# Wraps Rails form helpers with project-standard styling, error handling, and
# layout (sections, groups, toggles). Use `form_with` as the main entry point;
# it defaults to the custom FormBuilder below.
#
# How this file works
# -------------------
# FormBuilder overrides every standard Rails field helper (text_field, select,
# check_box, etc.) using the same pattern:
#
#   1. Alias the original as `helper!` (e.g. `text_field!`) so `super` still
#      reaches Rails' implementation.
#   2. Extract our custom kwargs — `label:`, `hint:`, `size:` — before they
#      reach Rails (which would choke on unknown options).
#   3. Call `super` to get the raw `<input>` HTML.
#   4. Wrap it in `form_group` which adds the label, hint text, error messages,
#      and the grid-column `size` container.
#
# Adding a new field type
# -----------------------
# For text_field-like inputs (single value, standard options hash), add the
# symbol to the array at the `text_field-like things` loop. That's it — you
# get label, hint, size, error styling, and form_group wrapping for free.
#
# For fields with non-standard signatures (like `select` or `collection_select`),
# write an explicit method following the same alias → extract → super → wrap
# pattern. See `select` or `check_box` for examples.
#
# Key private methods
# -------------------
# - `extract_label`      — pulls `label:` from kwargs, falls back to humanized
#                          method name, returns nil for `label: false`
# - `element_classes`    — Tailwind classes for text inputs, with error ring
# - `checkbox_classes`   — same idea, checkbox-specific classes
# - `with_error_classes` — shared conditional: error ring vs normal ring
# - `form_group`         — the label + input + hint + errors container
#
# Testing: test/helpers/form_helper_test.rb
module FormHelper
  # default to custom builder
  def form_with(*, **kwargs, &)
    kwargs[:builder] ||= FormBuilder

    # Extract customization parameters
    size = kwargs.delete(:size)
    spacing = kwargs.delete(:spacing)
    padding = kwargs.delete(:padding)
    permanence = kwargs.delete(:permanence)

    # Build custom classes or use defaults (pass false to opt out)
    custom_classes = []
    custom_classes << default_class(spacing, "space-y-12")
    custom_classes << default_class(size, "max-w-prose")
    custom_classes << default_class(padding, "px-4 @sm:px-6 @lg:px-8")

    append_class!(kwargs, custom_classes.join(" "))

    # Add Turbo permanence if requested
    if permanence
      kwargs[:data] ||= {}
      kwargs[:data][:turbo_permanent] = true
      kwargs[:data][:controller] = [ kwargs[:data][:controller], "form-reset" ].compact.join(" ")
    end

    model = kwargs[:model]

    # Handle nested resources - extract the actual model object
    actual_model = case model
    when Array
      model.last # For nested resources like [@workflow, @process_step], use the last one
    else
      model
    end

    # Capture the original block content
    compact = spacing == false
    original_block = block_given? ? proc { |f|
      f.compact = true if compact
      yield(f)
    } : nil

    # Create a new block that includes error summary if model has errors
    if actual_model && actual_model.respond_to?(:errors) && actual_model.errors.any? && original_block
      super(*, **kwargs) do |f|
        error_summary = render("shared/forms/error_summary", model: actual_model)
        form_content = capture { original_block.call(f) }
        error_summary + form_content
      end
    else
      super(*, **kwargs, &original_block)
    end
  end

  # Standalone toggle field helper that can be used outside of form_with blocks
  def toggle_field(object_name, method, label, caption: nil, hint: nil, size: nil, data: {}, value: false)
    render "shared/forms/toggle",
           form: nil,
           object_name: object_name,
           method: method,
           field_id: sanitized_field_id(object_name, method),
           label: label,
           caption: caption,
           hint: hint,
           size: size,
           data: data,
           value: value
  end

  def sortable_position_field(object, param_prefix = nil)
    param_prefix ||= "#{object.class.model_name.param_key}_positions"
    hidden_field_tag(
      "#{param_prefix}[#{object.id}]",
      object.position,
      data: { sortable_target: "position" },
    )
  end

  def filter_toggle(label, param:, checked: false, caption: nil, size: nil)
    render "shared/filter_toggle",
           label: label,
           param: param,
           checked: checked,
           caption: caption,
           size: size
  end

  private

  # Builds a DOM-safe field ID from an object name and method, for use outside
  # of FormBuilder (which has its own `field_id` from Rails).
  def sanitized_field_id(object_name, method)
    "#{object_name}_#{method}".tr("[]", "_").gsub(/[^-a-zA-Z0-9_]/, "_").squeeze("_")
  end

  # Custom form builder that wraps every standard Rails field helper with
  # Tailwind styling, label/hint rendering, and inline error display.
  class FormBuilder < ActionView::Helpers::FormBuilder
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include HtmlHelper
    include AppendHelper

    # When true, the form uses compact spacing (spacing: false). Adjusts
    # defaults in actions() so callers don't need manual margin overrides.
    attr_accessor :compact

    def link_action(*, **kwargs)
      tag.div(class: "@sm:ml-0 inline") do
        append_class!(kwargs, "text-zinc-700 dark:text-zinc-300", "text-sm")
        link_to(*, **kwargs)
      end
    end

    def cancel_link(url = "", **kwargs)
      if url == :close
        tag.div(class: "w-full @sm:w-auto @sm:ml-0") do
          tag.button("Cancel", type: "button",
                     class: "w-full @sm:w-auto px-3 py-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100 bg-white dark:bg-zinc-800 rounded-md shadow-sm ring-1 ring-inset ring-zinc-300 dark:ring-zinc-600 hover:bg-zinc-50 dark:hover:bg-zinc-700 @sm:text-zinc-700 @sm:dark:text-zinc-300 @sm:bg-transparent @sm:shadow-none @sm:ring-0 @sm:hover:bg-transparent cursor-pointer",
                     data: { action: "modal#close" }, **kwargs)
        end
      else
        link_action "Cancel", url, **kwargs
      end
    end

    def back_link(url = "")
      link_action "Back", url
    end

    def modal_actions(**kwargs, &)
      kwargs[:margin_classes] ||= []
      kwargs[:classes] = classnames(kwargs[:classes],
        "border-t border-zinc-200 dark:border-zinc-700 px-4 py-3 @sm:px-6")
      actions(**kwargs, &)
    end

    def actions(classes: "", margin_classes: nil, &)
      margin_classes ||= compact ? [ "mt-10" ] : [ "-mt-5", "pb-5" ]
      raise ArgumentError, "Block is required for actions" unless block_given?

      default_classes = [ "flex", "items-center", "justify-start", "gap-x-3" ]
      classes = classnames(classes, default_classes, margin_classes)

      content = @template.capture(&)
      @template.concat tag.div(content, class: classes)
    end

    # Captures optional header actions inside a `section` block.
    class SectionBuilder
      attr_reader :header_action_content

      def initialize(template)
        @template = template
        @header_action_content = nil
      end

      def header_action(&)
        raise ArgumentError, "Block is required for header_action" unless block_given?

        @header_action_content = @template.capture(&)
      end
    end

    def section(title = nil, text = nil, grid: true, separator: true, margin: "mt-6", classes: "", &)
      builder = SectionBuilder.new(@template)
      body_content = @template.capture { yield(builder) }
      header_action_content = builder.header_action_content

      container_classes = classnames(
        separator ? "mt-10 pt-8 border-t border-zinc-900/10 dark:border-zinc-700" : margin
      ).presence

      section_classes = classes.dup
      section_classes = classnames(section_classes, "mt-6") if title

      if grid
        section_classes = classnames(section_classes, "grid grid-cols-1 gap-x-6 gap-y-8 @sm:grid-cols-12")
      else
        section_classes = classnames(section_classes, "flex flex-col space-y-8")
      end

      @template.concat @template.render("shared/forms/section",
        title: title,
        text: text,
        body_content: body_content,
        header_action_content: header_action_content,
        container_classes: container_classes,
        section_classes: section_classes)
    end

    def form_group(input, method, label, label_tag: true, label_before: true, label_after: false, size: nil)
      size = @template.default_class(size, "@sm:col-span-6")
      if label_tag && label
        label = tag.label(label, for: field_id(method), class: "block text-sm/6 font-medium text-zinc-900 dark:text-zinc-100")
      end

      content = []

      if label_before && label
        content << label
      end

      # if we don't have a label, just assume we don't want a form group at all
      if label
        content << tag.div(input, class: "mt-2")
      else
        content << input
      end

      if label_after && label
        content << label
      end

      if object && object.errors[method].any?
        errors = object.errors[method]
        content << tag.p(@template.safe_join(errors, tag.br), class: "mt-2 text-sm text-danger-600 dark:text-danger-400")
      end

      tag.div(@template.safe_join(content, " "), class: size)
    end

    def element_classes(method)
      with_error_classes(method,
        [ "block", "w-full", "py-1.5",
          "rounded-md", "border-0", "text-zinc-900",
          "ring-1", "ring-inset",
          "placeholder:text-zinc-400",
          "focus:ring-2", "focus:ring-inset", "@sm:text-sm/6",
          "dark:bg-zinc-800", "dark:border-zinc-600", "dark:text-zinc-100",
          "dark:placeholder:text-zinc-500" ],
        error: %w[ring-danger-300 dark:ring-danger-500 focus:ring-danger-600 dark:focus:ring-danger-400],
        normal: %w[ring-zinc-300 dark:ring-zinc-600 focus:ring-primary-600 dark:focus:ring-primary-500])
    end

    # all these have the same idea of params with a single options at the end
    [
      :file_field, :radio_button
    ].each do |helper|
      alias_method :"#{helper}!", helper

      define_method(helper) do |method, *args, **kwargs, &blk|
        size = kwargs.delete(:size)
        label = extract_label(method, kwargs)
        hint = kwargs.delete(:hint)

        input = super(method, *args, **kwargs, &blk)

        if hint
          input += tag.p(hint, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400")
        end

        form_group(input, method, label, size:)
      end
    end

    alias text_area! text_area
    def text_area(method, *, **kwargs, &)
      label = extract_label(method, kwargs)
      size = kwargs.delete(:size)
      hint = kwargs.delete(:hint)

      append_class!(kwargs, element_classes(method))

      input = super

      if hint
        input += tag.p(hint, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400")
      end

      form_group(input, method, label, size:)
    end

    # text_field-like things
    [
      :text_field, :password_field, :telephone_field, :search_field,
      :time_field, :datetime_field, :month_field, :week_field, :url_field,
      :email_field, :number_field, :range_field, :color_field
    ].each do |helper|
      alias_method :"#{helper}!", helper

      define_method(helper) do |method, *args, **kwargs, &blk|
        label = extract_label(method, kwargs)
        size = kwargs.delete(:size)
        hint = kwargs.delete(:hint)

        append_class!(kwargs, element_classes(method), {
          "px-2.5 bg-white dark:bg-zinc-800 h-9" => helper == :color_field
        })

        input = super(method, *args, **kwargs, &blk)

        if hint
          input += tag.p(hint, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400")
        end

        form_group(input, method, label, size:)
      end
    end

    alias check_box! check_box
    def check_box(method, label = nil, *, **kwargs, &)
      label ||= extract_label(method, kwargs)
      size = kwargs.delete(:size) || "@sm:col-span-6"

      append_class!(kwargs, checkbox_classes(method))

      input = super(method, *, **kwargs, &)
      label_el = tag.label(label, for: field_id(method), class: "text-sm/6 font-medium text-zinc-900 dark:text-zinc-100")

      content = []
      content << tag.div(class: "flex items-center gap-2 mt-2") do
        @template.safe_join([ input, label_el ])
      end

      if object && object.errors[method].any?
        errors = object.errors[method]
        content << tag.p(@template.safe_join(errors, tag.br), class: "mt-2 text-sm text-danger-600 dark:text-danger-400")
      end

      tag.div(@template.safe_join(content), class: size)
    end

    def toggle(method, label = nil, caption: nil, hint: nil, size: nil, data: {}, **kwargs)
      label ||= extract_label(method, kwargs)

      @template.render "shared/forms/toggle",
                       form: self,
                       object_name: object_name,
                       method: method,
                       field_id: field_id(method),
                       label: label,
                       caption: caption,
                       hint: hint,
                       size: size,
                       data: data,
                       **kwargs
    end

    # Searchable combobox — a text input with a filterable dropdown list.
    # choices: array of [label, value] pairs, like options_for_select.
    # Pass url: for remote mode (GET url?q=term → JSON [{ label, value }, …]).
    def combobox(method, choices, label: nil, hint: nil, size: nil, include_blank: nil, placeholder: nil, value: nil, url: nil)
      label = extract_label(method, { label: label })
      selected_value = value || object&.public_send(method)
      selected_label = choices.find { |_l, v| v.to_s == selected_value.to_s }&.first

      @template.render "shared/forms/combobox",
                       form: self,
                       method: method,
                       choices: choices,
                       field_id: field_id(method),
                       label: label,
                       hint: hint,
                       size: size,
                       selected_value: selected_value,
                       selected_label: selected_label,
                       placeholder: placeholder,
                       include_blank: include_blank,
                       url: url
    end

    # Segmented control — a horizontal pill bar for mutually exclusive choices.
    # choices: array of [label, value] pairs, like options_for_select.
    def segmented_control(method, choices, label: nil, hint: nil, size: nil, value: nil)
      label = extract_label(method, { label: label })
      selected = value || object&.public_send(method)

      @template.render "shared/forms/segmented_control",
                       form: self,
                       method: method,
                       choices: choices,
                       field_id: field_id(method),
                       label: label,
                       hint: hint,
                       size: size,
                       selected: selected
    end

    alias date_field! date_field
    def date_field(method, **kwargs)
      append_controller!("datepicker", kwargs)
      text_field(method, **kwargs)
    end

    alias select! select
    def select(method, choices = nil, options = {}, html_options = {})
      if options.delete(:search)
        append_controller!(:select, html_options)
      else
        append_class!(html_options, element_classes(method))
      end

      submit_on_select = options.delete(:submit_on_select)

      # Add data-select-submit-on-select-value attribute if true
      if submit_on_select
        html_options[:data] ||= {}
        html_options[:data][:select_submit_on_select_value] = "true"
      end

      size = options.delete(:size)
      hint = options.delete(:hint)

      label = extract_label(method, options)
      input = super

      if hint
        input += tag.p(hint, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400")
      end

      form_group(input, method, label, size:)
    end

    alias collection_select! collection_select
    def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
      if options.delete(:search)
        append_controller!(:select, html_options)
      else
        append_class!(html_options, element_classes(method))
      end

      size = options.delete(:size)
      hint = options.delete(:hint)

      label = extract_label(method, options)
      input = super

      if hint
        input += tag.p(hint, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400")
      end

      form_group(input, method, label, size:)
    end

    alias submit! submit
    def submit(value = nil, **kwargs)
      append_class!(kwargs, submit_classes)
      super
    end

    private

    # Extracts a label from kwargs[:label], falling back to the humanized method name.
    # Returns nil when label is explicitly `false`.
    def extract_label(method, kwargs = nil)
      if kwargs
        label = kwargs.delete(:label)
      end

      return nil if label == false

      label || method.to_s.humanize.titleize
    end

    def checkbox_classes(method)
      with_error_classes(method,
        [ "h-5 w-5", "rounded",
          "border-zinc-300", "dark:border-zinc-600",
          "text-primary-600", "dark:text-primary-500",
          "dark:bg-zinc-800",
          "focus:ring-2", "focus:ring-offset-0" ],
        error: %w[focus:ring-danger-600 dark:focus:ring-danger-400],
        normal: %w[focus:ring-primary-600 dark:focus:ring-primary-500])
    end

    def with_error_classes(method, base, error:, normal:)
      has_errors = object.respond_to?(:errors) && object.errors[method].any?
      base + [ has_errors ? error : normal ]
    end

    def submit_classes
      @template.button_classes(type: :primary, size: :md, shadow: false)
    end
  end
end
