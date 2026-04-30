# Renders a horizontal stage bar for linear multi-step processes.
# Each stage shows a status icon, label, and optional hint text,
# connected by lines that encode progression state.
# Reusable across workflows (Problem pipeline, bugs, plans, etc.).
#
#   <%= stage_bar(stages, current: :problem) %>
#
# stages is an array of hashes:
#   [
#     { key: :problem, label: "Problem", hint: "Ready", path: "/projects/1/problem",
#       status: :completed },
#     { key: :research, label: "Research", hint: "Running...",
#       path: "/projects/1/research", status: :active },
#     { key: :tickets, label: "Tickets", status: :pending }
#   ]
#
# status values: :completed, :active, :pending, :failed
module StageBarHelper
  # Renders the full stage bar as a secondary header band.
  def stage_bar(stages, current:)
    tag.nav(class: "stage-bar") do
      tag.div(class: "stage-bar-container") do
        tag.div(class: "stage-bar-track") do
          parts = stages.each_with_index.map do |stage, i|
            item = stage_bar_item(stage, current:)
            if i < stages.length - 1
              item + stage_bar_connector(stages[i][:status])
            else
              item
            end
          end
          safe_join(parts)
        end
      end
    end
  end

  # Small circle indicator for compact sub-step rows.
  # Shared across stepper and stage bar contexts.
  def stage_bar_small_circle(status)
    case status
    when :completed
      tag.div(class: "status-circle sm completed") do
        icon(:check, classes: "status-circle-icon sm", variant: :solid)
      end
    when :active
      tag.div(class: "status-circle sm active") do
        tag.div(class: "status-circle-dot sm")
      end
    when :failed
      tag.div(class: "status-circle sm failed") do
        icon(:x_mark, classes: "status-circle-icon sm", variant: :solid)
      end
    else
      tag.div(class: "status-circle sm pending") do
        tag.div(class: "status-circle-dot sm")
      end
    end
  end

  private

  # Renders a single stage item with icon, label, and optional hint.
  def stage_bar_item(stage, current:)
    is_current = stage[:key] == current
    content = stage_bar_icon(stage[:status]) +
      stage_bar_label(stage[:label], stage[:status], current: is_current) +
      stage_bar_hint(stage[:hint], stage[:status])

    if stage[:path] && !is_current
      tag.a(content, href: stage[:path],
        class: "stage-bar-item stage-bar-link")
    else
      tag.span(content, class: "stage-bar-item")
    end
  end

  # Horizontal line between stages. Solid for completed/failed, dashed for incomplete.
  def stage_bar_connector(from_status)
    solid = from_status == :completed || from_status == :failed
    tag.span(class: classnames("stage-bar-connector", { "solid" => solid }))
  end

  # Status icon: check_circle (completed), x_circle (failed), filled dot (active), open dot (pending).
  def stage_bar_icon(status)
    case status
    when :completed
      icon(:check_circle, variant: :solid, classes: "stage-bar-icon completed")
    when :failed
      icon(:x_circle, variant: :solid, classes: "stage-bar-icon failed")
    when :active
      tag.span(class: "stage-bar-dot-wrap") do
        tag.span(class: "stage-bar-dot active")
      end
    else
      tag.span(class: "stage-bar-dot-wrap") do
        tag.span(class: "stage-bar-dot pending")
      end
    end
  end

  # Stage label text with color based on status.
  def stage_bar_label(label, status, current:)
    color = case status
    when :completed then "completed"
    when :active then "active"
    when :failed then "failed"
    end
    tag.span(label, class: classnames("stage-bar-label", color, { "current" => current }))
  end

  # Optional hint text after the label.
  def stage_bar_hint(hint, status)
    return "".html_safe if hint.blank?

    color = case status
    when :completed then "completed"
    when :active then "active"
    when :failed then "failed"
    end
    tag.span(hint, class: classnames("stage-bar-hint", color))
  end
end
