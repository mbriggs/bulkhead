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
    classes = if is_current
      "flex items-center gap-x-2 px-3 py-1.5 mx-2 text-sm font-medium rounded-md " \
      "bg-primary-50 text-primary-700 dark:bg-primary-900/30 dark:text-primary-400"
    else
      "flex items-center gap-x-2 px-3 py-1.5 mx-2 text-sm font-medium rounded-md " \
      "text-zinc-600 hover:bg-zinc-50 hover:text-zinc-900 " \
      "dark:text-zinc-400 dark:hover:bg-zinc-700/50 dark:hover:text-zinc-200"
    end

    link_to path, class: classes do
      out = "".html_safe
      out += icon(icon, classes: "h-4 w-4") if icon
      out += content_tag(:span, label)
      out
    end
  end

  # Mobile tab link with active/inactive states.
  def admin_nav_tab(label, path, is_current)
    classes = classnames(
      "inline-flex items-center px-3 py-2.5 text-sm font-medium border-b-2 whitespace-nowrap",
      {
        "border-primary-500 text-primary-600 dark:text-primary-400" => is_current,
        "border-transparent text-zinc-500 hover:text-zinc-700 hover:border-zinc-300 dark:text-zinc-400 dark:hover:text-zinc-300" => !is_current
      }
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
    tag.div(class: "mt-8") do
      header = tag.div(class: "mb-4") do
        h = tag.h3(title, class: "text-lg font-medium text-zinc-900 dark:text-zinc-100")
        h += tag.p(description, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400") if description
        h
      end
      header + body
    end
  end

  # ── Card ───────────────────────────────────────────────────────────────

  # Callout card with title and description, plus optional action block.
  # Uses shadow: false since it's nested inside the admin page card.
  def admin_action_card(title, description: nil, &block)
    tag.div(class: card_classes("p-4 @sm:p-6", shadow: false)) do
      content = tag.div(class: "flex items-center justify-between") do
        left = tag.div do
          h = tag.h4(title, class: "text-sm font-medium text-zinc-900 dark:text-zinc-100")
          h += tag.p(description, class: "mt-1 text-sm text-zinc-500 dark:text-zinc-400") if description
          h
        end
        right = block_given? ? tag.div(class: "ml-4 flex-shrink-0") { capture(&block) } : "".html_safe
        left + right
      end
      content
    end
  end

  # ── Alert ──────────────────────────────────────────────────────────────

  # Delegates to AlertsHelper#alert.
  def admin_alert(type, title:, description: nil)
    color = { info: :blue, success: :green, warning: :yellow, error: :red }.fetch(type)
    alert(icon: alert_icon(type), title: title, content: description, color: color)
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

  PROGRESS_COLORS = {
    green:  "bg-success-500",
    blue:   "bg-info-500",
    yellow: "bg-warning-500",
    red:    "bg-danger-500",
    zinc:   "bg-zinc-500"
  }.freeze

  # Horizontal progress bar.
  def admin_progress_bar(percentage, color: :blue)
    bar_color = PROGRESS_COLORS.fetch(color, PROGRESS_COLORS[:blue])
    clamped = [ [ percentage.to_f, 0 ].max, 100 ].min

    tag.div(class: "w-full bg-zinc-200 dark:bg-zinc-700 rounded-full h-2") do
      tag.div("", class: "#{bar_color} h-2 rounded-full", style: "width: #{clamped}%")
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

  private

  def alert_icon(type)
    case type
    when :info    then :information_circle
    when :success then :check_circle
    when :warning then :exclamation_triangle
    when :error   then :x_circle
    end
  end
end
