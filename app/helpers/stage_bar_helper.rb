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
    tag.nav(class: "border-b border-zinc-200 dark:border-zinc-700 bg-transparent mt-10 mb-8") do
      tag.div(class: "mx-auto max-w-7xl px-4 @sm:px-6 @lg:px-8") do
        tag.div(class: "flex items-center justify-center pt-4 pb-10 w-3/4 mx-auto") do
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

  # Small circle indicator (h-4 w-4) for compact sub-step rows.
  # Shared across stepper and stage bar contexts.
  def stage_bar_small_circle(status)
    case status
    when :completed
      tag.div(class: "flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-success-500") do
        icon(:check, classes: "h-2.5 w-2.5 text-white", variant: :solid)
      end
    when :active
      tag.div(class: "flex h-4 w-4 shrink-0 items-center justify-center rounded-full border-2 border-info-500") do
        tag.div(class: "h-1.5 w-1.5 rounded-full bg-info-500 animate-pulse")
      end
    when :failed
      tag.div(class: "flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-danger-500") do
        icon(:x_mark, classes: "h-2.5 w-2.5 text-white", variant: :solid)
      end
    else
      tag.div(class: "flex h-4 w-4 shrink-0 items-center justify-center rounded-full border-2 border-zinc-300 dark:border-zinc-600") do
        tag.div(class: "h-1.5 w-1.5 rounded-full bg-zinc-300 dark:bg-zinc-600")
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
        class: "flex items-center gap-2 shrink-0 hover:opacity-80 transition-opacity")
    else
      tag.span(content, class: "flex items-center gap-2 shrink-0")
    end
  end

  # Horizontal line between stages. Solid for completed/failed, dashed for incomplete.
  def stage_bar_connector(from_status)
    style = (from_status == :completed || from_status == :failed) ? "border-solid" : "border-dashed"
    tag.span(class: "flex-1 mx-6 h-px border-t border-zinc-300 dark:border-zinc-600 #{style}")
  end

  # Status icon: check_circle (completed), x_circle (failed), filled dot (active), open dot (pending).
  def stage_bar_icon(status)
    case status
    when :completed
      icon(:check_circle, variant: :solid, classes: "h-6 w-6 text-success-500 dark:text-success-400")
    when :failed
      icon(:x_circle, variant: :solid, classes: "h-6 w-6 text-danger-500 dark:text-danger-400")
    when :active
      tag.span(class: "flex h-6 w-6 items-center justify-center") do
        tag.span(class: "h-3.5 w-3.5 rounded-full bg-primary-500 dark:bg-primary-400")
      end
    else
      tag.span(class: "flex h-6 w-6 items-center justify-center") do
        tag.span(class: "h-3.5 w-3.5 rounded-full border-2 border-zinc-300 dark:border-zinc-600")
      end
    end
  end

  # Stage label text with color based on status.
  def stage_bar_label(label, status, current:)
    color = case status
    when :completed then "font-semibold text-zinc-700 dark:text-zinc-300"
    when :active then "font-semibold text-zinc-900 dark:text-zinc-100"
    when :failed then "font-semibold text-danger-600 dark:text-danger-400"
    else "font-semibold text-zinc-400 dark:text-zinc-500"
    end
    color += " underline underline-offset-[6px] decoration-2 decoration-primary-500 dark:decoration-primary-400" if current
    tag.span(label, class: "text-base #{color}")
  end

  # Optional hint text after the label.
  def stage_bar_hint(hint, status)
    return "".html_safe if hint.blank?

    color = case status
    when :completed, :active then "text-zinc-500 dark:text-zinc-400"
    when :failed then "text-danger-500 dark:text-danger-400"
    else "text-zinc-400 dark:text-zinc-500"
    end
    tag.span(hint, class: "text-sm -ml-1 #{color}")
  end
end
