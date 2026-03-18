module PageHelper
  def page(columns: "@lg:grid-cols-2", gap: "gap-6", controller: nil, values: {}, &block)
    columns = nil if columns == false
    columns = "@lg:grid-cols-#{columns}" if columns.is_a?(Integer)

    # Build data attributes
    data_attrs = {}

    if controller
      data_attrs[:controller] = controller
    end

    # Add any data values
    values.each do |key, value|
      # Convert key to proper data attribute format
      controller_prefix = controller&.tr("-", "_") || ""
      data_attrs[:"#{controller_prefix}_#{key}_value"] = value
    end

    content_tag(:div, class: "mx-auto max-w-7xl px-4 @sm:px-6 @lg:px-8", data: data_attrs) do
      content_tag(:div, class: "grid grid-cols-1 #{columns} #{gap}", &block)
    end
  end

  def page_separator(visible: true, size: :md)
    base_classes = visible ? "border-zinc-900/5 dark:border-zinc-700" : "border-0"

    spacing_classes = case size
    when :sm
      visible ? "my-5 @lg:my-6" : "mb-4 @lg:mb-5"
    when :md
      visible ? "my-7 @lg:my-10" : "mb-5 @lg:mb-8"
    when :lg
      visible ? "my-9 @lg:my-14" : "mb-6 @lg:mb-11"
    end

    tag.hr class: "#{base_classes} #{spacing_classes}"
  end

  def page_title?
    content_for?(:page_title)
  end

  def page_title(title)
    content_for(:page_title, title)
  end

  def page_breadcrumbs(*crumbs)
    crumbs = crumbs.map do |text, url|
      page_crumb(text, url:)
    end

    separator = icon(:chevron_right, classes: "h-5 w-5 flex-shrink-0 text-zinc-400 dark:text-zinc-500")

    tag.nav(safe_join(crumbs, separator), class: "flex items-center space-x-2 @sm:space-x-4")
  end

  def page_crumb(text, url: nil)
    classes = "text-sm font-medium text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"

    if url
      tag.a(text, href: url, class: classes)
    else
      tag.span(text, class: classes)
    end
  end

  def page_datem(icon_name, text)
    svg = icon(icon_name, classes: "mr-1.5 h-5 w-5 flex-shrink-0 text-zinc-400 dark:text-zinc-500")
    content = svg + sanitize(text)

    tag.div(content, class: "mt-2 flex items-center text-sm text-zinc-500 dark:text-zinc-400")
  end

  # Standalone section helper for use outside forms.
  # Renders the same partial as the form builder's section method.
  #
  # Usage:
  #   <%= section "Variants" do %>
  #     <p>Content here</p>
  #   <% end %>
  #
  #   <%= section "Details", text: "Optional description", separator: false do %>
  #     <p>Content here</p>
  #   <% end %>
  #
  def section(title = nil, text: nil, grid: false, separator: false, margin: "mt-6", classes: "", &block)
    body_content = capture(&block)

    container_classes = classnames(
      separator ? "mt-10 pt-8 border-t border-zinc-900/10 dark:border-zinc-700" : margin
    ).presence

    section_classes = classes.dup
    section_classes = classnames(section_classes, "mt-6") if title

    if grid
      section_classes = classnames(section_classes, "grid grid-cols-1 gap-x-6 gap-y-8 @sm:grid-cols-12")
    end

    render "shared/forms/section",
      title: title,
      text: text,
      body_content: body_content,
      header_action_content: nil,
      container_classes: container_classes,
      section_classes: section_classes
  end

  class PageHeaderBuilder
    include ActionView::Helpers::DateHelper

    def initialize
      @breadcrumbs = []
      @primary_actions = []
      @actions = []
      @data = []
      @dropdown_actions = []
      @custom_entries = []
      @reader_mode_entries = []
    end

    def breadcrumb(name, url)
      @breadcrumbs << [ name, url ]
    end

    def action(name = nil, url = nil, **opts)
      name ||= opts.delete(:name)
      url ||= opts.delete(:url)
      @actions << [ name, url, opts ]
    end

    def primary_action(name = nil, url = nil, **opts)
      name ||= opts.delete(:name)
      url ||= opts.delete(:url)
      @primary_actions << [ name, url, opts ]
    end

    def dropdown_action(name, items, **opts)
      @dropdown_actions << [ name, items, opts ]
    end

    # Inject arbitrary pre-rendered HTML into the header actions area.
    def custom(html)
      @custom_entries << html
    end

    # Add a reader mode button + dialog to the header actions area.
    # The block receives view context and should return the dialog body content.
    def reader_mode(name, title:, &block)
      @reader_mode_entries << { name:, title:, block: }
    end

    def datem(icon, text)
      @data << [ icon, text ]
    end

    def datem_timestamps(record)
      datem :calendar, "Created #{time_ago_in_words record.created_at} ago"
      datem :calendar, "Last Updated #{time_ago_in_words record.updated_at} ago"
    end

    def to_state
      [ @breadcrumbs, @primary_actions, @actions, @data, @dropdown_actions, @custom_entries, @reader_mode_entries ]
    end
  end

  # Sidebar column for use inside a 12-column page grid.
  #
  #   <%= page(columns: "@lg:grid-cols-12") do %>
  #     <div class="@lg:col-span-8">...</div>
  #     <%= page_sidebar(sticky: true) do %>
  #       <%= detail_card do |c| %>...
  #     <% end %>
  #   <% end %>
  def page_sidebar(sticky: false, size: :default, &block)
    col_span = size == :small ? "@lg:col-span-3" : "@lg:col-span-4"
    classes = "#{col_span} space-y-6"
    classes = "#{classes} @lg:sticky @lg:top-6 self-start" if sticky

    content_tag(:div, class: classes, &block)
  end

  def page_header(title, sticky: false, separator: true)
    if !page_title?
      page_title(title)
    end

    header = PageHeaderBuilder.new

    if block_given?
      capture do
        yield(header)
      end
    end

    breadcrumbs, primary_actions, actions, data, dropdown_actions, custom_entries, reader_mode_entries = header.to_state

    # Resolve reader_mode entries into custom_entries (needs view context for helpers)
    reader_mode_entries.each do |entry|
      html = reader_mode do
        button(entry[:name], type: :secondary, size: :lg, data: { action: "reader-mode#open" }) +
          reader_mode_dialog(title: entry[:title]) { capture(&entry[:block]) }
      end
      custom_entries << html
    end

    breadcrumbs = page_breadcrumbs(*breadcrumbs)

    render partial: "shared/page/header", locals: {
      title:, breadcrumbs:,
      primary_actions:, actions:,
      data:, dropdown_actions:,
      custom_entries:,
      sticky:, separator:
    }
  end
end
