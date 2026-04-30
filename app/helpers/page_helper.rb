module PageHelper
  PAGE_COLUMN_CLASSES = {
    1 => "cols-1",
    2 => "cols-2",
    3 => "cols-3",
    4 => "cols-4",
    8 => "cols-8",
    12 => "cols-12"
  }.freeze

  PAGE_GAP_CLASSES = {
    default: "gap-default",
    compact: "gap-compact",
    spacious: "gap-spacious"
  }.freeze

  def page(columns: 2, gap: :default, controller: nil, values: {}, &block)
    columns = nil if columns == false
    columns = PAGE_COLUMN_CLASSES.fetch(columns, columns.to_s) if columns
    gap = PAGE_GAP_CLASSES.fetch(gap, gap.to_s)

    # Build data attributes
    data_attrs = {}

    if controller
      data_attrs[:controller] = controller
    end

    controller_prefix = controller&.tr("-", "_") || ""
    values.each do |key, value|
      data_attrs[:"#{controller_prefix}_#{key}_value"] = value
    end

    content_tag(:div, class: "page", data: data_attrs) do
      content_tag(:div, class: classnames("page-grid", columns, gap), &block)
    end
  end

  def page_separator(visible: true, size: :md)
    tag.hr class: classnames(
      "separator",
      "#{size}",
      { "borderless" => !visible }
    )
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

    separator = icon(:chevron_right, classes: "breadcrumbs-separator")

    tag.nav(safe_join(crumbs, separator), class: "breadcrumbs")
  end

  def page_crumb(text, url: nil)
    classes = "breadcrumbs-item"

    if url
      tag.a(text, href: url, class: classes)
    else
      tag.span(text, class: classes)
    end
  end

  def page_datem(icon_name, text)
    svg = icon(icon_name, classes: "page-header-datum-icon")
    content = svg + sanitize(text)

    tag.div(content, class: "page-header-datum")
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
  def section(title = nil, text: nil, grid: false, separator: false, margin: "spaced", classes: "", &block)
    body_content = capture(&block)

    container_classes = classnames(
      separator ? "section separated" : classnames("section", margin)
    ).presence

    section_classes = classes.dup
    section_classes = classnames(section_classes, "section-body", { "with-title" => title })

    if grid
      section_classes = classnames(section_classes, "grid")
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
  #   <%= page(columns: 12) do %>
  #     <div class="span-8">...</div>
  #     <%= page_sidebar(sticky: true) do %>
  #       <%= detail_card do |c| %>...
  #     <% end %>
  #   <% end %>
  def page_sidebar(sticky: false, size: :default, &block)
    classes = classnames(
      "page-sidebar",
      size == :small ? "small" : "default",
      { "sticky" => sticky }
    )

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
