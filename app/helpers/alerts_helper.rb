module AlertsHelper
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
    case color
    when :yellow
      container_color = "bg-warning-50 dark:bg-warning-900/20"
      icon_color = "text-warning-400 dark:text-warning-300"
      header_color = "text-warning-800 dark:text-warning-200"
      content_color = "text-warning-700 dark:text-warning-300"
    when :green
      container_color = "bg-success-50 dark:bg-success-900/20"
      icon_color = "text-success-400 dark:text-success-300"
      header_color = "text-success-800 dark:text-success-200"
      content_color = "text-success-700 dark:text-success-300"
    when :red
      container_color = "bg-danger-50 dark:bg-danger-900/20"
      icon_color = "text-danger-400 dark:text-danger-300"
      header_color = "text-danger-800 dark:text-danger-200"
      content_color = "text-danger-700 dark:text-danger-300"
    when :blue
      container_color = "bg-info-50 dark:bg-info-900/20"
      icon_color = "text-info-400 dark:text-info-300"
      header_color = "text-info-800 dark:text-info-200"
      content_color = "text-info-700 dark:text-info-300"
    else
      raise "color #{color} not supported"
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
      content = tag.ul(class: "list-disc space-y-1 pl-5") do
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

    rendered_icon = icon(icon, classes: classnames(icon_color, "h-5 w-5", icon_classes))

    render partial: "shared/ui/alert", locals: {
      icon: rendered_icon, title:, content:,
      container_color:, header_color:, content_color:,
      disclosure:
    }
  end
end
