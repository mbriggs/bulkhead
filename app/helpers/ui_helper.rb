module UiHelper
  def sortable_handle(icon_name: :bars_3, classes: "h-5 w-5 text-zinc-400 dark:text-zinc-500")
    icon(icon_name, classes:, data: { sortable_target: "handle" })
  end

  TOOLTIP_POSITIONS = {
    top: "bottom-full left-1/2 mb-2 -translate-x-1/2",
    bottom: "top-full left-1/2 mt-2 -translate-x-1/2",
    left: "right-full top-1/2 mr-2 -translate-y-1/2",
    right: "left-full top-1/2 ml-2 -translate-y-1/2"
  }.freeze

  TOOLTIP_ARROWS = {
    top: "top-full left-1/2 -mt-1 -translate-x-1/2",
    bottom: "bottom-full left-1/2 -mb-1 -translate-x-1/2",
    left: "left-full top-1/2 -ml-1 -translate-y-1/2",
    right: "right-full top-1/2 -mr-1 -translate-y-1/2"
  }.freeze

  TOOLTIP_ARROW_BORDERS = {
    top: "border-t-zinc-900 dark:border-t-zinc-100",
    bottom: "border-b-zinc-900 dark:border-b-zinc-100",
    left: "border-l-zinc-900 dark:border-l-zinc-100",
    right: "border-r-zinc-900 dark:border-r-zinc-100"
  }.freeze

  def tooltip(text, position: :top, classes: nil, &block)
    # Default to inline-block for standalone tooltips, but allow override for flex contexts
    css_classes = classes || "inline-block"
    content_tag(:div, class: "group relative #{css_classes}".strip) do
      concat(capture(&block))
      concat(
        content_tag(:div, class: "absolute #{TOOLTIP_POSITIONS[position]} transform opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10") do
          content_tag(:div, class: "rounded bg-zinc-900 dark:bg-zinc-100 px-2 py-1 text-xs text-white dark:text-zinc-900 whitespace-nowrap") do
            concat(text)
            concat(
              content_tag(:div, class: "absolute #{TOOLTIP_ARROWS[position]} transform") do
                content_tag(:div, "", class: "border-4 border-transparent #{TOOLTIP_ARROW_BORDERS[position]}")
              end,
            )
          end
        end,
      )
    end
  end

  # Pill badge with custom color classes.
  # Semantic helpers (status_badge) delegate here.
  # Accepts a block for rich content (e.g. text + remove button).
  def badge(text = nil, colors:, &block)
    css = "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium #{colors}"
    if block
      tag.span(class: css, &block)
    else
      tag.span(text, class: css)
    end
  end

  # Badge with an inline remove button. Submits a DELETE to the given path.
  #
  #   removable_badge("iheartjane", remove_path: project_repository_path(@project, pr),
  #                   colors: "bg-primary-50 ...", turbo_frame: "repositories_123")
  def removable_badge(text, remove_path:, colors:, turbo_frame: nil)
    badge(colors:) do
      remove_btn = button_to(remove_path,
        method: :delete,
        class: "ml-0.5 inline-flex items-center hover:text-primary-900 dark:hover:text-primary-200",
        data: { turbo_frame: }.compact) do
        icon(:x_mark, classes: "h-3 w-3")
      end
      safe_join([ text, remove_btn ])
    end
  end

  # Shared severity-level color classes for badges.
  # Normalizes "moderate" → "medium" so callers can use either vocabulary.
  #
  #   severity_colors("high")     # => "bg-orange-100 text-orange-700 ..."
  #   severity_colors("moderate") # => "bg-yellow-100 text-yellow-700 ..."
  SEVERITY_LEVEL_COLORS = {
    "low"      => "bg-success-100 text-success-700 dark:bg-success-900/30 dark:text-success-400",
    "medium"   => "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
    "moderate" => "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400",
    "high"     => "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
    "critical" => "bg-danger-100 text-danger-700 dark:bg-danger-900/30 dark:text-danger-400"
  }.freeze

  # Returns Tailwind color classes for a severity level string.
  def severity_colors(level)
    SEVERITY_LEVEL_COLORS.fetch(level.to_s, SEVERITY_LEVEL_COLORS["low"])
  end

  # Status badge for boolean active/inactive states
  #
  # @param active [Boolean] Whether the entity is active
  # @param style [Symbol] :badge for pill style, :text for simple colored text
  # @param labels [Hash] Custom labels, defaults to { true => "Active", false => "Inactive" }
  #
  # Examples:
  #   status_badge(user.active?)
  #   status_badge(device.active?, style: :text)
  #   status_badge(record.enabled?, labels: { true => "Enabled", false => "Disabled" })
  def status_badge(active, style: :badge, labels: { true => "Active", false => "Inactive" })
    label = labels[active]

    case style
    when :badge
      colors = if active
        "bg-success-100 text-success-700 dark:bg-success-900/30 dark:text-success-400"
      else
        "bg-zinc-100 text-zinc-700 dark:bg-zinc-700 dark:text-zinc-300"
      end
      badge(label, colors:)
    when :text
      colors = active ? "text-success-600 dark:text-success-400" : "text-zinc-400 dark:text-zinc-500"
      tag.span(label, class: colors)
    else
      raise ArgumentError, "Unknown style: #{style}. Use :badge or :text"
    end
  end

  # Empty state placeholder for lists and collections.
  #
  # @param message [String] Required description text
  # @param icon [Symbol] Heroicon name, defaults to :inbox
  # @param title [String] Optional main heading
  # @param action_text [String] Optional button text
  # @param action_path [String] Optional button URL
  # @param classes [String] Additional wrapper classes
  #
  # Examples:
  #   empty_state("No items found")
  #   empty_state("No orders yet", icon: :shopping_bag, title: "Your cart is empty")
  #   empty_state("Add items to get started", action_text: "Add Item", action_path: new_item_path)
  def empty_state(message, icon: :inbox, title: nil, action_text: nil, action_path: nil, classes: "py-12")
    render "shared/ui/empty_state",
      message:,
      icon:,
      title:,
      action_text:,
      action_path:,
      classes:
  end

  # Image tag with a block fallback shown when the image fails to load.
  #
  #   <%= avatar_img("https://example.com/photo.jpg", class: "h-8 w-8 rounded-full") do %>
  #     <span class="text-xs font-medium text-white">M</span>
  #   <% end %>
  def avatar_img(url, **options, &block)
    fallback_id = "avatar-fallback-#{SecureRandom.hex(4)}"
    onerror = "this.style.display='none';document.getElementById('#{fallback_id}').style.display=''"

    img = tag.img(src: url, alt: "", onerror:, **options)
    fallback_span = tag.span(id: fallback_id, style: "display:none", &block)

    img + fallback_span
  end

  SAFE_URL_SCHEMES = %w[http https mailto].freeze

  # Returns the URL if it uses a safe scheme, nil otherwise.
  # Blocks javascript:, data:, and other dangerous schemes in user-supplied URLs.
  def safe_url(url)
    return nil if url.blank?

    normalized = url.strip.gsub(/[\x00\t\n\r]/, "")
    uri = URI.parse(normalized)

    # Schemeless/relative URLs are safe (resolve against current origin)
    return normalized if uri.scheme.nil?

    SAFE_URL_SCHEMES.include?(uri.scheme.downcase) ? normalized : nil
  rescue URI::InvalidURIError
    nil
  end

  # -- Markdown rendering pipeline -----------------------------------------

  # Renders markdown text as HTML with prose styling.
  # Defense-in-depth: sanitize with an allowlist after Commonmarker rendering
  # so a parser bypass can't escalate to stored XSS.
  #
  # Pass `compact: true` for supplementary content (revision notes) where
  # headings should be scaled down to avoid competing with primary content.
  # Pass `sidebar: true` for sidebar summaries — minimal spacing, no margins,
  # small text that reads as a dense blurb rather than formatted content.
  def render_markdown(text, compact: false, sidebar: false, plan: false)
    return "".html_safe if text.blank?
    clean = sanitize_markdown(text)
    classes = "prose prose-sm dark:prose-invert"
    classes += " max-w-none" unless plan
    classes += " prose-compact" if compact
    classes += " prose-sidebar" if sidebar
    classes += " prose-plan" if plan
    data = sidebar ? {} : { controller: "code-block-copy" }
    tag.div(clean, class: classes, data: data)
  end

  # HTML tags allowed through sanitization after Commonmarker renders markdown.
  # Defense-in-depth: even though Commonmarker runs with unsafe: false, this
  # allowlist prevents any parser bypass from escalating to stored XSS.
  MARKDOWN_TAGS = %w[
    h1 h2 h3 h4 h5 h6 p br hr
    ul ol li blockquote pre code span
    em strong del a img input
    table thead tbody tfoot tr th td
  ].freeze

  MARKDOWN_ATTRIBUTES = {
    "a" => %w[href title],
    "img" => %w[src alt title],
    "th" => %w[align],
    "td" => %w[align],
    "code" => %w[class],
    "span" => %w[class],
    "pre" => %w[lang],
    "input" => %w[type checked disabled]
  }.freeze

  # Renders markdown to HTML and sanitizes with an allowlist.
  # Single point of control for the Commonmarker → sanitize pipeline.
  # Used by ProblemHelper (render_markdown, truncated_markdown) and the
  # research stepper for agent run summaries.
  def sanitize_markdown(text)
    cache_key = "markdown/#{Digest::SHA256.hexdigest(text)}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) {
      html = Commonmarker.to_html(
        text,
        options: { render: { unsafe: false } },
        plugins: { syntax_highlighter: { theme: "base16-ocean.dark" } }
      )
      sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRIBUTES)
    }.html_safe
  end

  # Horizontal rule with spacing above and below.
  def spacer(classes: nil)
    tag.hr(class: classnames("border-zinc-200 dark:border-zinc-700 mt-3 mb-5", classes))
  end

  # Truncates long text to a number of lines with an inline "more…" / "less…" toggle.
  #
  #   <%= truncated_text("Long text here...", lines: 3) %>
  #
  def truncated_text(text, lines: 3)
    tag.div(data: { controller: "truncate", truncate_lines_value: lines }, class: "relative") do
      tag.p(text, class: "whitespace-pre-wrap line-clamp-#{lines}", data: { truncate_target: "content" }) +
      tag.button("more\u2026",
        data: { truncate_target: "toggle", action: "truncate#toggle" },
        class: "hidden absolute bottom-0 right-0 text-sm text-primary-600 dark:text-primary-400 " \
               "hover:underline cursor-pointer bg-gradient-to-l from-white from-60% via-white " \
               "dark:from-zinc-800 dark:via-zinc-800 to-transparent pl-8 pr-0.5")
    end
  end

  # Loading skeleton helper for Turbo Frame placeholders
  def loading_skeleton(rows: 2, title: true)
    content_tag(:div, class: "animate-pulse") do
      content = []

      # Add title skeleton if requested
      if title
        content << content_tag(:div, "", class: "h-8 bg-zinc-200 dark:bg-zinc-700 rounded mb-4")
      end

      # Add row skeletons
      if rows.positive?
        content << content_tag(:div, class: "space-y-3") do
          safe_join(Array.new(rows) { content_tag(:div, "", class: "h-10 bg-zinc-200 dark:bg-zinc-700 rounded") })
        end
      end

      safe_join(content)
    end
  end
end
