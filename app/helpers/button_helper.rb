module ButtonHelper
  # Shared across all solid (filled) button types
  SOLID_BASE = %w[
    text-white
    dark:ring-1 dark:ring-inset dark:ring-white/15
    focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
  ].freeze

  # Per-color classes for solid buttons — bg, hover, dark variants, focus outline
  SOLID_COLORS = {
    primary: %w[
      bg-primary-500 hover:bg-primary-400 active:bg-primary-600
      dark:bg-primary-500 dark:hover:bg-primary-400 dark:active:bg-primary-600
      focus-visible:outline-primary-500 dark:focus-visible:outline-primary-400
    ],
    danger: %w[
      bg-danger-500 hover:bg-danger-400 active:bg-danger-600
      dark:bg-danger-500 dark:hover:bg-danger-400 dark:active:bg-danger-600
      focus-visible:outline-danger-500 dark:focus-visible:outline-danger-400
    ]
  }.freeze

  SIZES = {
    xs: %w[rounded text-xs px-2 py-1],
    sm: %w[rounded text-sm px-2.5 py-2],
    md: %w[rounded-md text-sm px-3 py-2],
    lg: %w[rounded-md text-sm px-4 py-2],
    xl: %w[rounded-md text-sm px-4.5 py-2.5]
  }.freeze

  SECONDARY = %w[
    bg-white text-zinc-700
    ring-1 ring-inset ring-zinc-300 hover:bg-zinc-50 active:bg-zinc-100
    dark:bg-zinc-800 dark:text-zinc-300
    dark:ring-zinc-600 dark:hover:bg-zinc-700 dark:active:bg-zinc-900
  ].freeze

  SOFT = %w[
    bg-primary-50 text-primary-600 hover:bg-primary-100 active:bg-primary-200
    dark:bg-primary-900/75 dark:text-primary-400 dark:hover:bg-primary-800/75 dark:active:bg-primary-900
    dark:ring-1 dark:ring-inset dark:ring-primary-500/20
  ].freeze

  # Class string for button elements. Pass `shadow: false` for buttons
  # rendered inside cards to avoid stacking shadows.
  def button_classes(*, type: :secondary, size: :md, shadow: true)
    if type == :link
      return classnames("inline-block", *)
    end

    classes = %w[font-semibold inline-flex items-center transition-colors duration-100 disabled:opacity-50 disabled:cursor-not-allowed]
    classes << "shadow-sm dark:shadow" if shadow

    case type
    when :primary, :danger
      classes << SOLID_BASE
      classes << SOLID_COLORS[type]
    when :secondary
      classes << SECONDARY
    when :soft
      classes << SOFT
    end

    classes << SIZES[size]
    classnames(*classes, *)
  end

  def button(name = "", type: :primary, size: :md, shadow: true, url: nil, icon_right: false, icon_name: nil, classes: nil, confirm: nil, tooltip_text: nil, tooltip_position: :top, modal: false, **kwargs, &)
    append_confirm!(kwargs, confirm)

    if url
      return button_link(name, url, type:, size:, shadow:, classes:, tooltip_text:, tooltip_position:, modal:, **kwargs, &)
    end

    if modal
      kwargs[:data] ||= {}
      kwargs[:data][:action] = "click->modal#open"
    end

    button_class = button_classes(classes, type:, size:, shadow:)

    content = name
    if icon_name
      icon_color = SOLID_COLORS.key?(type) ? "text-white/80" : "text-zinc-400 dark:text-zinc-500"

      if icon_right
        rendered_icon = icon(icon_name, classes: "-mr-1 ml-1.5 h-5 w-5 #{icon_color}")
        content = safe_join([ sanitize(name), " ", rendered_icon ])
      else
        rendered_icon = icon(icon_name, classes: "-ml-0.5 mr-1.5 h-5 w-5 #{icon_color}")
        content = safe_join([ rendered_icon, " ", sanitize(name) ])
      end
    end

    button_element = tag.button(content, class: button_class, **kwargs, &)

    if tooltip_text
      tooltip(tooltip_text, position: tooltip_position) { button_element }
    else
      button_element
    end
  end

  def button_link(*, type: :primary, size: :md, shadow: true, classes: nil, confirm: nil, tooltip_text: nil, tooltip_position: :top, modal: false, **kwargs, &)
    append_confirm!(kwargs, confirm)

    if modal
      kwargs[:data] ||= {}
      kwargs[:data][:action] = "click->modal#open"
    end

    # Convert method option to data-turbo-method for Turbo
    if kwargs[:method] && kwargs[:method] != :get
      kwargs[:data] ||= {}
      kwargs[:data][:turbo_method] = kwargs.delete(:method)
    end

    classes = button_classes(classes, type:, size:, shadow:)
    link_element = link_to(*, **kwargs, class: classes, &)

    if tooltip_text
      tooltip(tooltip_text, position: tooltip_position) { link_element }
    else
      link_element
    end
  end
end
