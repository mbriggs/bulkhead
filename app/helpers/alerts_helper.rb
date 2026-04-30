module AlertsHelper
  ALERT_TONES = %i[info success warning danger].freeze

  def notice_alert(title, notice = nil)
    alert(
      title:,
      content: notice,
      icon: :information_circle,
      color: :blue,
    )
  end

  def success_alert(title, message = nil, disclosure: false)
    alert(
      title:,
      content: message,
      icon: :check_circle,
      color: :green,
      disclosure:
    )
  end

  def error_alert(title = nil, error = nil, disclosure: false)
    alert(
      title:, content: error,
      icon: :x_circle,
      color: :red,
      disclosure:
    )
  end

  def alert(icon:, title:, content:, color:, disclosure: false, icon_classes: nil)
    # Strict per the README contract: alerts surface caller bugs (e.g.
    # color: :sucess) instead of silently rendering an info alert.
    tone = Bulkhead::Tones.normalize!(color)
    unless ALERT_TONES.map(&:to_s).include?(tone)
      raise ArgumentError, "Unsupported alert tone: #{color.inspect}. Allowed: #{ALERT_TONES.inspect}"
    end

    # Handle title - check if it's a hash with :html or "html" key
    if title.is_a?(Hash) && (title[:html] || title["html"])
      title = sanitize(title[:html] || title["html"])
    end

    # Handle hash format for HTML content
    if content.is_a?(Hash) && (content[:html] || content["html"])
      content = tag.p(sanitize(content[:html] || content["html"]))
    elsif content.present? && !content.is_a?(Array)
      content = tag.p(content)
    end

    if content.present? && content.is_a?(Array)
      content = tag.ul(class: "alert-list") do
        safe_join(content.map do |message|
          # Check if array element is a hash with :html or "html" key
          if message.is_a?(Hash) && (message[:html] || message["html"])
            tag.li(sanitize(message[:html] || message["html"]))
          else
            tag.li(message)
          end
        end)
      end
    end

    rendered_icon = icon(icon, classes: classnames("alert-icon", icon_classes))

    render partial: "shared/ui/alert", locals: {
      icon: rendered_icon, title:, content:,
      tone:,
      disclosure:
    }
  end
end
