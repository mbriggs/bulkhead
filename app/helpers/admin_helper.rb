# UI helpers for the admin namespace.
#
# Provides stat grids, definition lists, tabs, section wrappers,
# and other admin-specific layout primitives. Built on top of the
# existing helper system (CardHelper, AlertsHelper, HtmlHelper).
#
#   <%= admin_page(current: "jobs") do %>
#     <%= admin_stat_grid do |g| %>
#       <% g.stat "Total Jobs", 42, color: :blue %>
#     <% end %>
#   <% end %>
#
module AdminHelper
  # Wraps admin content in a card with sidebar navigation.
  # Sidebar visible on @md+ container widths, collapses to tabs on narrow.
  def admin_page(current:, &block)
    body = capture(&block)
    card = render(partial: "admin/shared/page", locals: { current: current, body: body })
    page(columns: false) { card }
  end

  # Sidebar nav link with active/inactive states.
  def admin_nav_item(label, path, is_current, icon: nil)
    classes = classnames("admin-nav-item", { "active" => is_current })

    link_to path, class: classes do
      out = "".html_safe
      out += icon(icon, classes: "admin-nav-icon") if icon
      out += content_tag(:span, label)
      out
    end
  end

  # Mobile tab link with active/inactive states.
  def admin_nav_tab(label, path, is_current)
    classes = classnames(
      "admin-nav-tabs-tab",
      { "active" => is_current }
    )

    link_to label, path, class: classes
  end

  # ── Stat Grid ──────────────────────────────────────────────────────────

  class AdminStatGridBuilder
    Stat = Struct.new(:label, :value, :color, :href, :hint, keyword_init: true)

    def initialize
      @stats = []
    end

    # Adds a borderless dot-style counter to the stat grid.
    # Optional +hint+ renders as a title tooltip on hover.
    def stat(label, value, color: :zinc, href: nil, hint: nil)
      @stats << Stat.new(label: label, value: value, color: color, href: href, hint: hint)
    end

    def to_stats
      @stats
    end
  end

  # Renders a responsive grid of borderless dot-style stat counters.
  #
  #   <%= admin_stat_grid do |g| %>
  #     <% g.stat "Ready", 10, color: :blue %>
  #     <% g.stat "Failed", 3, color: :red, href: admin_jobs_path(status: "failed") %>
  #   <% end %>
  def admin_stat_grid(&block)
    builder = AdminStatGridBuilder.new
    capture { yield builder }
    render partial: "admin/shared/stat_grid", locals: { stats: builder.to_stats }
  end

  # ── Section ────────────────────────────────────────────────────────────

  # Titled section wrapper with optional description.
  def admin_section(title, description: nil, &block)
    body = capture(&block)
    tag.div(class: "admin-section") do
      header = tag.div(class: "admin-section-header") do
        h = tag.h3(title, class: "admin-section-title")
        h += tag.p(description, class: "admin-section-description") if description
        h
      end
      header + body
    end
  end

  # ── Card ───────────────────────────────────────────────────────────────

  # Callout card with title and description, plus optional action block.
  # Uses shadow: false since it's nested inside the admin page card.
  def admin_action_card(title, description: nil, &block)
    tag.div(class: card_classes("padded", shadow: false)) do
      content = tag.div(class: "admin-action") do
        left = tag.div do
          h = tag.h4(title, class: "admin-action-title")
          h += tag.p(description, class: "admin-action-description") if description
          h
        end
        right = block_given? ? tag.div(class: "admin-action-controls") { capture(&block) } : "".html_safe
        left + right
      end
      content
    end
  end

  # ── Alert ──────────────────────────────────────────────────────────────

  ADMIN_ALERT_ICONS = {
    info:    :information_circle,
    success: :check_circle,
    warning: :exclamation_triangle,
    error:   :x_circle
  }.freeze
  ADMIN_ALERT_TYPES = ADMIN_ALERT_ICONS.keys.freeze

  # Delegates to AlertsHelper#alert. Restricted to a small, opinionated set of
  # types so the icon mapping and tone stay in lockstep.
  def admin_alert(type, title:, description: nil)
    icon_name = ADMIN_ALERT_ICONS[type] or raise ArgumentError,
      "admin_alert type must be one of #{ADMIN_ALERT_TYPES.inspect}, got #{type.inspect}"
    alert(icon: icon_name, title: title, content: description, color: type)
  end

  # ── Definition List ────────────────────────────────────────────────────

  class AdminDefinitionListBuilder
    Item = Struct.new(:label, :value, :span, keyword_init: true)

    def initialize
      @items = []
    end

    def item(label, value = nil, span: 1, &block)
      @items << Item.new(label: label, value: value || block, span: span)
    end

    def to_items
      @items
    end
  end

  # Key-value definition list in a responsive grid.
  #
  #   <%= admin_definition_list(columns: 3) do |dl| %>
  #     <% dl.item "Status", "Running" %>
  #     <% dl.item "Error", span: 3 do %>
  #       <pre><%= @job.error_trace %></pre>
  #     <% end %>
  #   <% end %>
  def admin_definition_list(columns: 2, &block)
    builder = AdminDefinitionListBuilder.new
    capture { yield builder }
    render partial: "admin/shared/definition_list", locals: { items: builder.to_items, columns: columns }
  end

  # ── Progress Bar ───────────────────────────────────────────────────────

  PROGRESS_BAR_TONES = %i[info primary success warning danger default].freeze

  # Horizontal progress bar. `color` accepts a canonical tone (e.g. :success,
  # :warning, :danger, :info, :primary, :default) or its alias (:green, :red,
  # :blue, :zinc). Unknown values fall back to :info.
  def admin_progress_bar(percentage, color: :info)
    tone = Bulkhead::Tones.coerce(color, allow: PROGRESS_BAR_TONES, default: :info)
    clamped = [ [ percentage.to_f, 0 ].max, 100 ].min

    tag.div(class: "progress") do
      tag.div("", class: classnames("progress-bar", tone), style: "width: #{clamped}%")
    end
  end

  # ── Tabs ───────────────────────────────────────────────────────────────

  class AdminTabsBuilder
    Tab = Struct.new(:label, :href, :count, :active, keyword_init: true)

    def initialize
      @tabs = []
    end

    def tab(label, href:, count: nil, active: false)
      @tabs << Tab.new(label: label, href: href, count: count, active: active)
    end

    def to_tabs
      @tabs
    end
  end

  # Pill-style tabs with optional counts.
  #
  #   <%= admin_tabs do |t| %>
  #     <% t.tab "All", href: admin_jobs_path, count: 100, active: true %>
  #     <% t.tab "Failed", href: admin_jobs_path(status: "failed"), count: 3 %>
  #   <% end %>
  def admin_tabs(&block)
    builder = AdminTabsBuilder.new
    capture { yield builder }
    render partial: "admin/shared/tabs", locals: { tabs: builder.to_tabs }
  end

  # Formats a USD cost value for display.
  def format_admin_cost(cost)
    cost ? "$#{'%.2f' % cost}" : "$0.00"
  end

  # Formats a duration in seconds for display.
  def format_admin_duration(seconds)
    seconds ? "#{seconds}s" : "\u2014"
  end

end
