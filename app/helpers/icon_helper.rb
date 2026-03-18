module IconHelper
  # Render a Heroicon by name.
  #
  # Accepts symbol names with underscores (hub convention) or string names with
  # hyphens (heroicons gem convention). Underscores are automatically converted
  # to hyphens so callers can use either style.
  #
  #   icon(:check_circle)                        # outline check-circle
  #   icon(:check_circle, variant: :solid)        # solid check-circle
  #   icon(:check_circle, classes: "h-5 w-5")     # with Tailwind classes
  #
  def icon(name, classes: nil, variant: :outline, **attrs)
    icon_name = name.to_s.tr("_", "-")
    options = attrs.merge(class: classes).compact
    heroicon icon_name, variant: variant, options: options
  end

  # Backward-compatible alias for hub's icon_by_name.
  def icon_by_name(name, classes: nil, **attrs)
    icon(name, classes: classes, **attrs)
  end

  # Render the Jane heart logo as an inline SVG.
  #
  #   jane_heart_icon(classes: "h-5 w-5")
  #
  def jane_heart_icon(classes: nil, **attrs)
    tag.svg(
      viewBox: "154 0 124 102",
      fill: "none",
      xmlns: "http://www.w3.org/2000/svg",
      class: classes,
      **attrs
    ) do
      tag.path(
        d: "M216.252 14.834C211.527 8.624 202.388 0 188.017 0c-18.465 0-33.121 16.615-33.121 " \
           "33.043 0 16.433 8.23 29.3 24.695 44.105 16.408 14.76 22.042 16.247 36.589 24.027 " \
           "14.697-7.78 20.336-9.267 36.739-24.027 16.465-14.805 24.689-27.672 24.689-44.105 " \
           "0-16.428-14.65-33.043-33.12-33.043-14.366 0-23.511 8.624-28.236 14.834Z",
        fill: "#FFC220"
      )
    end
  end

  # Render a Heroicon wrapped in a link.
  #
  #   icon_link_to(:trash, item_path(item), tooltip_text: "Delete", data: { turbo_method: :delete })
  #
  def icon_link_to(icon_name, url, tooltip_text: nil, tooltip_position: :top, classes: "link-icon", **link_options)
    content = icon(icon_name, classes: classes)

    if tooltip_text
      link_to(url, **link_options) { tooltip(tooltip_text, position: tooltip_position) { content } }
    else
      link_to(url, **link_options) { content }
    end
  end
end
