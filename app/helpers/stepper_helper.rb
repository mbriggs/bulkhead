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

    tag.div(class: card_classes("p-6 @sm:p-8")) do
      stepper_header_from_source(source) +
        tag.div(class: "mt-6") do
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
    tag.div(class: "flex gap-3") do
      stepper_indicator_column(step.status, last:) +
        stepper_content_column(step)
    end
  end

  # Left column: circle indicator + connecting line.
  def stepper_indicator_column(status, last:)
    tag.div(class: "flex flex-col items-center") do
      indicator = stepper_circle(status)
      line = unless last
        line_color = case status
        when :completed then "bg-success-500"
        when :failed    then "bg-danger-300"
        else "bg-zinc-200 dark:bg-zinc-700"
        end
        tag.div(class: "w-0.5 grow #{line_color}")
      end
      indicator + (line || "".html_safe)
    end
  end

  # Circle indicator for each step status.
  def stepper_circle(status)
    case status
    when :completed
      tag.div(class: "flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-success-500") do
        icon(:check, classes: "h-3.5 w-3.5 text-white", variant: :solid)
      end
    when :active
      tag.div(class: "flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 border-info-500") do
        tag.div(class: "h-2 w-2 rounded-full bg-info-500 animate-pulse")
      end
    when :failed
      tag.div(class: "flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-danger-500") do
        icon(:x_mark, classes: "h-3.5 w-3.5 text-white", variant: :solid)
      end
    else # :pending
      tag.div(class: "flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 border-zinc-300 dark:border-zinc-600") do
        tag.div(class: "h-2 w-2 rounded-full bg-zinc-300 dark:bg-zinc-600")
      end
    end
  end

  # Smaller circle indicator for sub-steps. Delegates to StageBarHelper.
  def stepper_circle_small(status)
    stage_bar_small_circle(status)
  end

  # Right column: step label, optional children, and summary text.
  def stepper_content_column(step)
    tag.div(class: "min-w-0 pb-6") do
      label_color = case step.status
      when :completed then "text-zinc-900 dark:text-zinc-100"
      when :active    then "text-info-600 dark:text-info-400 font-medium"
      when :failed    then "text-danger-600 dark:text-danger-400 font-medium"
      else "text-zinc-400 dark:text-zinc-500"
      end

      content = tag.p(class: "text-sm #{label_color}") do
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
    tag.div(class: "mt-8 space-y-1.5") do
      safe_join(children.map { |child| stepper_child(child) })
    end
  end

  # Renders summary + detail link inside a truncation wrapper.
  def stepper_step_detail(step, text_size: "text-sm")
    has_content = step.summary.present? || step.summary_html.present?

    if has_content
      wrapper_data = { controller: "truncate", truncate_lines_value: 3 }
      wrapper_opts = { data: wrapper_data, class: "relative mt-1 max-w-prose" }
      if step.permanent_id
        wrapper_opts[:id] = step.permanent_id
        wrapper_data[:turbo_permanent] = ""
      end

      tag.div(**wrapper_opts) do
        tag.div(data: { truncate_target: "content" }, class: "line-clamp-3") do
          parts = "".html_safe
          if step.summary_html
            parts += tag.div(step.summary_html,
              class: "prose prose-sm dark:prose-invert max-w-none prose-sidebar " \
                     "text-zinc-500 dark:text-zinc-400")
          elsif step.summary
            parts += tag.p(step.summary,
              class: "#{text_size} text-zinc-500 dark:text-zinc-400 whitespace-pre-wrap break-words")
          end
          if step.detail_path && !step.hide_detail_link
            parts += tag.p(class: "mt-1") do
              link_to stepper_detail_label(step), step.detail_path,
                class: "text-xs text-indigo-600 dark:text-indigo-400 hover:underline"
            end
          end
          parts
        end +
          tag.button("more\u2026",
            data: { truncate_target: "toggle", action: "truncate#toggle" },
            class: "hidden absolute bottom-0 right-0 #{text_size} text-primary-600 dark:text-primary-400 " \
                   "hover:underline cursor-pointer bg-gradient-to-l from-white from-60% via-white " \
                   "dark:from-zinc-800 dark:via-zinc-800 to-transparent pl-8 pr-0.5")
      end
    elsif step.detail_path && !step.hide_detail_link
      tag.p(class: "mt-0.5") do
        link_to stepper_detail_label(step), step.detail_path,
          class: "text-xs text-indigo-600 dark:text-indigo-400 hover:underline"
      end
    else
      "".html_safe
    end
  end

  # One sub-step row: small circle + label + optional detail link.
  def stepper_child(child)
    label_color = case child.status
    when :completed then "text-zinc-700 dark:text-zinc-300"
    when :active    then "text-info-600 dark:text-info-400 font-medium"
    when :failed    then "text-danger-600 dark:text-danger-400 font-medium"
    else "text-zinc-400 dark:text-zinc-500"
    end

    tag.div(class: "flex items-start gap-2") do
      stepper_circle_small(child.status) +
        tag.div(class: "min-w-0") do
          tag.p(class: "text-xs #{label_color}") { child.label.html_safe + stepper_elapsed_suffix(child) } + # html_safe: labels are from constant maps only
            stepper_step_detail(child, text_size: "text-xs")
        end
    end
  end

  # Light grey elapsed time suffix for timed steps.
  def stepper_elapsed_suffix(step)
    return "".html_safe unless step.started_at

    if step.status == :completed && step.finished_at
      duration = elapsed_time_text(step.started_at, step.finished_at)
      tag.span(" \u00B7 #{duration}", class: "font-normal text-zinc-400 dark:text-zinc-500")
    elsif step.status == :active
      tag.span(" \u00B7 ", class: "font-normal text-zinc-400 dark:text-zinc-500") +
        tag.span(elapsed_time_text(step.started_at),
          class: "font-normal text-zinc-400 dark:text-zinc-500",
          data: { controller: "elapsed-time",
                  elapsed_time_started_at_value: step.started_at.iso8601 })
    else
      "".html_safe
    end
  end

  private

  # Renders the header from a source object's protocol methods.
  def stepper_header_from_source(source)
    tag.div(class: "flex items-center gap-3") do
      icon_classes = "h-5 w-5 #{source.header_icon_color} shrink-0"
      icon_classes += " animate-spin" if source.header_icon_animated?

      left = icon(source.header_icon, classes: icon_classes)
      left += if source.status == :failed || source.status == :paused
        tag.h3(source.header_title, class: "text-lg font-medium text-zinc-900 dark:text-zinc-100")
      else
        tag.h3(class: "text-lg font-medium text-zinc-900 dark:text-zinc-100") do
          "#{source.header_title} ".html_safe +
            tag.span(source.elapsed_since ? elapsed_time_text(source.elapsed_since) : "",
              class: "text-sm font-normal text-zinc-500 dark:text-zinc-400",
              data: source.elapsed_since ? {
                controller: "elapsed-time",
                elapsed_time_started_at_value: source.elapsed_since.iso8601
              } : {})
        end
      end

      right = if source.respond_to?(:active_detail_path) && source.active_detail_path
        tag.div(class: "ml-auto") do
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
      class: "inline-flex items-center gap-1.5 text-sm text-indigo-600 dark:text-indigo-400 hover:underline" do
      icon(:arrow_top_right_on_square, classes: "h-3.5 w-3.5") +
        tag.span(label || "View details")
    end
  end

  # Returns the detail link label for a step, with a sensible default.
  def stepper_detail_label(step)
    step.detail_label || "View details"
  end

  # Error section driven by the source protocol.
  def stepper_error_section_for(source)
    tag.div(class: "mt-4 rounded-md bg-danger-50 dark:bg-danger-900/20 p-4", data: { controller: "disclosure" }) do
      toggle = tag.button(
        class: "flex items-center gap-1.5 text-sm font-medium text-danger-700 dark:text-danger-400",
        data: { action: "disclosure#toggle" },
        "aria-expanded": "false"
      ) do
        icon(:chevron_right, classes: "h-4 w-4 transition-transform") +
          tag.span("Error details")
      end

      details = tag.div(
        class: "hidden mt-2 text-sm text-danger-600 dark:text-danger-400 whitespace-pre-wrap break-words",
        data: { disclosure_target: "content" }
      ) do
        tag.p(source.error_message)
      end

      actions = if source.retry_path
        tag.div(class: "mt-3") do
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
