module UiHelper
  TOOLTIP_POSITIONS = %i[top bottom left right].freeze
  PROGRESS_TONES = %i[default primary success warning danger info].freeze
  PROGRESS_SIZES = %i[xs sm md].freeze
  STATUS_DOT_TONES = %i[default primary success warning danger info].freeze

  def sortable_handle(icon_name: :bars_3, classes: "sortable-handle")
    icon(icon_name, classes:, data: { sortable_target: "handle" })
  end

  def tooltip(text, position: :top, classes: nil, &block)
    raise ArgumentError, "Unknown tooltip position: #{position}" unless TOOLTIP_POSITIONS.include?(position)

    pos = position.to_s
    css_classes = classes || "inline"

    # tabindex makes the wrapper focusable so keyboard users can reveal
    # the bubble via :focus-within. role/aria-describedby give the
    # tooltip text a programmatic association with its trigger.
    bubble_id = "tooltip-#{SecureRandom.hex(4)}"

    content_tag(:div,
      class: classnames("tooltip", css_classes),
      tabindex: 0,
      "aria-describedby": bubble_id) do
      concat(capture(&block))
      concat(
        content_tag(:div, id: bubble_id, role: "tooltip", class: classnames("tooltip-bubble", pos)) do
          content_tag(:div, class: "tooltip-content") do
            concat(text)
            concat(
              content_tag(:div, class: classnames("tooltip-arrow", pos)) do
                content_tag(:div, "", class: classnames("tooltip-arrow-shape", pos))
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
    css = "badge pill #{colors}"
    if block
      tag.span(class: css, &block)
    else
      tag.span(text, class: css)
    end
  end

  # Horizontal progress indicator with ARIA attributes. `value` and `total`
  # are numeric; tone controls the fill color.
  def progress_bar(value, total: 100, tone: :info, size: :md, classes: nil)
    tone = Bulkhead::Tones.coerce(tone, allow: PROGRESS_TONES, default: :info)
    size = size.to_sym
    raise ArgumentError, "Unknown progress size: #{size}" unless PROGRESS_SIZES.include?(size)

    total = total.to_i
    current = value.to_i
    pct = total.zero? ? 0 : ((current.to_f / total) * 100).clamp(0, 100)

    tag.span(
      class: classnames("progress", size, classes),
      role: "progressbar",
      aria: { valuenow: current, valuemin: 0, valuemax: total }
    ) do
      tag.span("", class: classnames("progress-bar", tone), style: "--progress-value: #{pct.round}%")
    end
  end

  # Compact status dot used in dense rows and live-state indicators.
  def status_dot(tone: :default, pulse: false, classes: nil)
    tone = Bulkhead::Tones.coerce(tone, allow: STATUS_DOT_TONES, default: :default)
    tag.span("", class: classnames("status-dot", tone, { "pulse" => pulse }, classes), aria: { hidden: true })
  end

  # Definition-list metric grid for small telemetry counters.
  def metric_grid(items, classes: nil)
    tag.dl(class: classnames("metric-grid", classes)) do
      safe_join(items.map do |label, value, tone|
        tag.div(class: classnames("metric", tone)) do
          tag.dt(label) + tag.dd(value)
        end
      end)
    end
  end

  # Badge with an inline remove button. Submits a DELETE to the given path.
  #
  #   removable_badge("iheartjane", remove_path: project_repository_path(@project, pr),
  #                   colors: "primary", turbo_frame: "repositories_123")
  def removable_badge(text, remove_path:, colors:, turbo_frame: nil)
    badge(colors:) do
      remove_btn = button_to(remove_path,
        method: :delete,
        class: "badge-remove",
        data: { turbo_frame: }.compact) do
        icon(:x_mark, classes: "badge-remove-icon")
      end
      safe_join([ text, remove_btn ])
    end
  end

  # Shared severity-level color classes for badges.
  # Normalizes "moderate" → "medium" so callers can use either vocabulary.
  #
  #   severity_colors("high")     # => "high"
  #   severity_colors("moderate") # => "warning"
  SEVERITY_LEVEL_COLORS = {
    "low"      => "success",
    "medium"   => "warning",
    "moderate" => "warning",
    "high"     => "high",
    "critical" => "danger"
  }.freeze

  # Returns color classes for a severity level string.
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
      colors = active ? "success" : "default"
      badge(label, colors:)
    when :text
      colors = active ? "status-text active" : "status-text inactive"
      tag.span(label, class: colors)
    else
      raise ArgumentError, "Unknown style: #{style}. Use :badge or :text"
    end
  end

  EMPTY_STATE_ILLUSTRATIONS = %i[no_results empty_inbox no_data error success permission loading].freeze

  # Empty state placeholder for lists and collections.
  #
  # @param message [String] Required description text
  # @param illustration [Symbol] Named line illustration; one of
  #   EMPTY_STATE_ILLUSTRATIONS. When set, supersedes `icon:`.
  # @param icon [Symbol] Heroicon name, defaults to :inbox. Used as
  #   fallback when `illustration:` is not given.
  # @param title [String] Optional main heading
  # @param action_text [String] Optional button text
  # @param action_path [String] Optional button URL
  # @param classes [String] Additional wrapper classes
  #
  # Examples:
  #   empty_state("No items found")
  #   empty_state("No orders yet", illustration: :empty_inbox, title: "Your cart is empty")
  #   empty_state("Couldn't find a match", illustration: :no_results)
  def empty_state(message, illustration: nil, icon: :inbox, title: nil, action_text: nil, action_path: nil, classes: "default-spacing")
    if illustration && !EMPTY_STATE_ILLUSTRATIONS.include?(illustration)
      raise ArgumentError, "Unknown empty-state illustration: #{illustration.inspect}. Allowed: #{EMPTY_STATE_ILLUSTRATIONS.inspect}"
    end

    render "shared/ui/empty_state",
      message:,
      illustration:,
      icon:,
      title:,
      action_text:,
      action_path:,
      classes:
  end

  # Image tag with a block fallback shown when the image fails to load.
  # Mounts the avatar Stimulus controller on the `<img>` itself (no wrapper
  # element, so existing layouts that expect img + fallback as direct children
  # of the parent stay intact) and locates the fallback by id. Caller-supplied
  # data attributes are merged, not clobbered: `data: { controller: "tooltip" }`
  # combines with the avatar controller via space-separated values.
  #
  #   <%= avatar_img("https://example.com/photo.jpg", class: "avatar sm") do %>
  #     <span class="avatar-fallback">M</span>
  #   <% end %>
  def avatar_img(url, **options, &block)
    fallback_id = "avatar-fallback-#{SecureRandom.hex(4)}"

    append_controller!(:avatar, options)
    append_value!(:avatar_fallback_id, fallback_id, options)
    options[:data][:action] = [ options[:data][:action], "error->avatar#fail" ].compact.join(" ").strip

    img = tag.img(src: url, alt: "", **options)
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

  # Renders markdown text as HTML with rich-text styling.
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
    classes = classnames("rich-text", {
      "unconstrained" => !plan,
      "compact"       => compact,
      "sidebar"       => sidebar,
      "plan"          => plan
    })
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

  MARKDOWN_ATTRIBUTES = %w[
    href title src alt align class lang
    type checked disabled
  ].freeze

  # Renders markdown to HTML and sanitizes with an allowlist.
  # Single point of control for the Commonmarker → sanitize pipeline.
  # Commonmarker is loaded lazily so hosts that don't render markdown
  # don't pay for the dependency.
  def sanitize_markdown(text)
    require_commonmarker!
    html = Commonmarker.to_html(
      text,
      options: { render: { unsafe: false } },
      plugins: { syntax_highlighter: { theme: "" } }
    )
    sanitize(html, tags: MARKDOWN_TAGS, attributes: MARKDOWN_ATTRIBUTES)
  end

  # Horizontal rule with spacing above and below.
  def spacer(classes: nil)
    tag.hr(class: classnames("spacer", classes))
  end

  # Truncates long text to a number of lines with an inline "more…" / "less…" toggle.
  #
  #   <%= truncated_text("Long text here...", lines: 3) %>
  #
  def truncated_text(text, lines: 3)
    lines = [ lines.to_i, 1 ].max

    tag.div(data: { controller: "truncate", truncate_lines_value: lines }, class: "truncate") do
      tag.p(text,
        class: "truncate-text sm line-clamp",
        style: "--bulkhead-line-clamp: #{lines}",
        data: { truncate_target: "content" }) +
      tag.button("more\u2026",
        data: { truncate_target: "toggle", action: "truncate#toggle" },
        class: "hidden truncate-toggle overlay truncate-text sm")
    end
  end

  # Loading skeleton helper for Turbo Frame placeholders
  def loading_skeleton(rows: 2, title: true)
    content_tag(:div, class: "skeleton") do
      content = []

      # Add title skeleton if requested
      if title
        content << content_tag(:div, "", class: "skeleton-title")
      end

      # Add row skeletons
      if rows.positive?
        content << content_tag(:div, class: "skeleton-rows") do
          safe_join(Array.new(rows) { content_tag(:div, "", class: "skeleton-row") })
        end
      end

      safe_join(content)
    end
  end

  private

  # Lazy-loads Commonmarker. Raises a friendly LoadError pointing at the
  # remediation step so hosts that don't render markdown don't carry the
  # dependency, and hosts that do render get an actionable failure mode.
  def require_commonmarker!
    return if defined?(Commonmarker)
    require "commonmarker"
  rescue LoadError
    raise LoadError, <<~MSG.chomp
      Bulkhead's render_markdown / sanitize_markdown require the "commonmarker" gem.

      Add it to your Gemfile and run bundle install:

        gem "commonmarker"
    MSG
  end
end
