# Renders a step-by-step progress indicator for any pipeline.
#
# Generic renderer driven by source objects that implement the stepper
# protocol (steps, status, header_title, etc.). Each pipeline provides
# its own source PORO that populates StepperStep structs.
#
#   <%= stepper(MySource.new(@record)) %>
#
module StepperHelper
  # Typed step data for the stepper renderer.
  # All fields except name, label, and status are optional (default nil/false).
  StepperStep = Struct.new(
    :name,             # Step identifier string (e.g. "evaluating")
    :label,            # Human-readable display text
    :status,           # :pending, :active, :completed, :failed
    :summary,          # Plain-text summary
    :summary_html,     # Pre-rendered HTML summary
    :permanent_id,     # HTML id for data-turbo-permanent (preserves truncate state)
    :started_at,       # Time when the step began (for elapsed time display)
    :finished_at,      # Time when the step completed (for elapsed time display)
    :detail_path,      # URL for "View details" link (nil to suppress)
    :detail_label,     # Custom label for the detail link (default: "View details")
    :children,         # Array of child StepperSteps (compound sub-steps)
    :hide_detail_link, # When true, suppresses inline detail link
    keyword_init: true
  )

  # Renders the full stepper card from a source object.
  def stepper(source)
    steps = source.steps
    failed = source.status == :failed

    tag.div(class: card_classes("stepper")) do
      stepper_header_from_source(source) +
        tag.div(class: "stepper-steps") do
          safe_join(steps.each_with_index.map { |step, i|
            stepper_step(step, last: i == steps.size - 1)
          })
        end +
        (failed && source.error_message ? stepper_error_section_for(source) : "".html_safe)
    end
  end

  # Server-rendered elapsed time to prevent empty-element content shift during morph.
  def elapsed_time_text(started_at, ended_at = Time.current)
    seconds = (ended_at - started_at).to_i
    hours, remainder = seconds.divmod(3600)
    minutes, secs = remainder.divmod(60)

    if hours > 0
      "#{hours}h #{minutes}m #{secs}s"
    elsif minutes > 0
      "#{minutes}m #{secs}s"
    else
      "#{secs}s"
    end
  end

  # -- Rendering primitives --

  # Renders one step row with indicator, label, and optional summary.
  def stepper_step(step, last:)
    tag.div(class: "stepper-step") do
      stepper_indicator_column(step.status, last:) +
        stepper_content_column(step)
    end
  end

  # Left column: circle indicator + connecting line.
  def stepper_indicator_column(status, last:)
    tag.div(class: "stepper-rail") do
      indicator = stepper_circle(status)
      line = unless last
        line_color = case status
        when :completed then "completed"
        when :failed    then "failed"
        end
        tag.div(class: classnames("stepper-line", line_color))
      end
      indicator + (line || "".html_safe)
    end
  end

  # Circle indicator for each step status.
  def stepper_circle(status)
    case status
    when :completed
      tag.div(class: "status-circle md completed") do
        icon(:check, classes: "status-circle-icon md", variant: :solid)
      end
    when :active
      tag.div(class: "status-circle md active") do
        tag.div(class: "status-circle-dot md")
      end
    when :failed
      tag.div(class: "status-circle md failed") do
        icon(:x_mark, classes: "status-circle-icon md", variant: :solid)
      end
    else # :pending
      tag.div(class: "status-circle md pending") do
        tag.div(class: "status-circle-dot md")
      end
    end
  end

  # Smaller circle indicator for sub-steps. Delegates to StageBarHelper.
  def stepper_circle_small(status)
    stage_bar_small_circle(status)
  end

  # Right column: step label, optional children, and summary text.
  def stepper_content_column(step)
    tag.div(class: "stepper-content") do
      label_color = case step.status
      when :completed then "completed"
      when :active    then "active"
      when :failed    then "failed"
      else "pending"
      end

      content = tag.p(class: classnames("stepper-label", label_color)) do
        step.label.html_safe + stepper_elapsed_suffix(step) # html_safe: labels are from constant maps only
      end
      content += stepper_step_detail(step)
      if step.children
        content += stepper_children(step.children)
      end
      content
    end
  end

  # Renders sub-steps as a compact list within a parent step's content.
  def stepper_children(children)
    tag.div(class: "stepper-children") do
      safe_join(children.map { |child| stepper_child(child) })
    end
  end

  # Renders summary + detail link inside a truncation wrapper.
  def stepper_step_detail(step, text_size: "text-sm")
    has_content = step.summary.present? || step.summary_html.present?
    compact = text_size == "text-xs"
    text_class = compact ? "xs" : "sm"
    detail_class = classnames("stepper-detail", { "compact" => compact })

    if has_content
      wrapper_data = { controller: "truncate", truncate_lines_value: 3 }
      wrapper_opts = { data: wrapper_data, class: "truncate" }
      if step.permanent_id
        wrapper_opts[:id] = step.permanent_id
        wrapper_data[:turbo_permanent] = ""
      end

      tag.div(**wrapper_opts) do
        tag.div(data: { truncate_target: "content" }, class: "line-clamp", style: "--bulkhead-line-clamp: 3") do
          parts = "".html_safe
          if step.summary_html
            parts += tag.div(step.summary_html,
              class: "truncate-rich-text rich-text sidebar")
          elsif step.summary
            parts += tag.p(step.summary,
              class: classnames("truncate-text", text_class))
          end
          if step.detail_path && !step.hide_detail_link
            parts += tag.p(class: "truncate-detail") do
              link_to stepper_detail_label(step), step.detail_path,
                class: detail_class
            end
          end
          parts
        end +
          tag.button("more\u2026",
            data: { truncate_target: "toggle", action: "truncate#toggle" },
            class: classnames("hidden truncate-toggle overlay", text_class))
      end
    elsif step.detail_path && !step.hide_detail_link
      tag.p(class: "truncate-detail") do
        link_to stepper_detail_label(step), step.detail_path,
          class: detail_class
      end
    else
      "".html_safe
    end
  end

  # One sub-step row: small circle + label + optional detail link.
  def stepper_child(child)
    label_color = case child.status
    when :completed then "completed"
    when :active    then "active"
    when :failed    then "failed"
    else "pending"
    end

    tag.div(class: "stepper-child") do
      stepper_circle_small(child.status) +
        tag.div(class: "stepper-child-content") do
          tag.p(class: classnames("stepper-child-label", label_color)) { child.label.html_safe + stepper_elapsed_suffix(child) } + # html_safe: labels are from constant maps only
            stepper_step_detail(child, text_size: "text-xs")
        end
    end
  end

  # Light grey elapsed time suffix for timed steps.
  def stepper_elapsed_suffix(step)
    return "".html_safe unless step.started_at

    if step.status == :completed && step.finished_at
      duration = elapsed_time_text(step.started_at, step.finished_at)
      tag.span(" \u00B7 #{duration}", class: "stepper-time")
    elsif step.status == :active
      tag.span(" \u00B7 ", class: "stepper-time") +
        tag.span(elapsed_time_text(step.started_at),
          class: "stepper-time",
          data: { controller: "elapsed-time",
                  elapsed_time_started_at_value: step.started_at.iso8601 })
    else
      "".html_safe
    end
  end

  private

  # Renders the header from a source object's protocol methods.
  def stepper_header_from_source(source)
    tag.div(class: "stepper-header") do
      icon_classes = classnames("stepper-header-icon", source.header_icon_color, {
        "spinning" => source.header_icon_animated?
      })

      left = icon(source.header_icon, classes: icon_classes)
      left += if source.status == :failed || source.status == :paused
        tag.h3(source.header_title, class: "stepper-title")
      else
        tag.h3(class: "stepper-title") do
          "#{source.header_title} ".html_safe +
            tag.span(source.elapsed_since ? elapsed_time_text(source.elapsed_since) : "",
              class: "stepper-title-time",
              data: source.elapsed_since ? {
                controller: "elapsed-time",
                elapsed_time_started_at_value: source.elapsed_since.iso8601
              } : {})
        end
      end

      right = if source.respond_to?(:active_detail_path) && source.active_detail_path
        tag.div(class: "stepper-header-action") do
          stepper_detail_link(source.active_detail_path, source.try(:active_detail_label))
        end
      else
        "".html_safe
      end

      left + right
    end
  end

  # Renders a "View details" link for the header.
  def stepper_detail_link(path, label = nil)
    return "".html_safe unless path

    link_to path,
      class: "stepper-detail" do
      icon(:arrow_top_right_on_square, classes: "stepper-detail-icon") +
        tag.span(label || "View details")
    end
  end

  # Returns the detail link label for a step, with a sensible default.
  def stepper_detail_label(step)
    step.detail_label || "View details"
  end

  # Error section driven by the source protocol.
  def stepper_error_section_for(source)
    tag.div(class: "stepper-error", data: { controller: "disclosure" }) do
      toggle = tag.button(
        class: "stepper-error-toggle",
        data: { action: "disclosure#toggle" },
        "aria-expanded": "false"
      ) do
        icon(:chevron_right, classes: "stepper-error-icon") +
          tag.span("Error details")
      end

      details = tag.div(
        class: "hidden stepper-error-details",
        data: { disclosure_target: "content" }
      ) do
        tag.p(source.error_message)
      end

      actions = if source.retry_path
        tag.div(class: "stepper-error-actions") do
          button_to source.retry_label, source.retry_path,
            method: :post,
            class: button_classes(type: :primary, size: :sm)
        end
      else
        "".html_safe
      end

      toggle + details + actions
    end
  end
end
