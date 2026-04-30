module ButtonHelper
  BUTTON_TYPES = %i[primary danger secondary soft link].freeze
  BUTTON_SIZES = %i[xs sm md lg xl].freeze

  # Class string for button elements. Pass `shadow: false` for buttons
  # rendered inside cards to avoid stacking shadows.
  def button_classes(*, type: :primary, size: :md, shadow: true)
    type = type.to_sym
    size = size.to_sym
    raise ArgumentError, "Unknown button type: #{type}" unless BUTTON_TYPES.include?(type)
    raise ArgumentError, "Unknown button size: #{size}" unless BUTTON_SIZES.include?(size)

    if type == :link
      return classnames("button", "link", *)
    end

    classes = [ "button", "#{type}", "#{size}" ]
    classes << "shadow" if shadow
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
      if icon_right
        rendered_icon = icon(icon_name, classes: "button-icon trailing")
        content = safe_join([ sanitize(name), " ", rendered_icon ])
      else
        rendered_icon = icon(icon_name, classes: "button-icon leading")
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
