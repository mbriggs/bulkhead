# Helpers for a full-page reading overlay using native <dialog>.
#
# Wraps content in a Stimulus-controlled reader mode with a sticky header
# for dismissal. Uses the same rendered markdown — the container CSS controls
# font size, not a separate render call.
#
#   <%= reader_mode do %>
#     <%= reader_mode_button(tooltip: "Expand") %>
#     <%= reader_mode_dialog(title: "Implementation Plan") do %>
#       <%= render_markdown(text, plan: true) %>
#     <% end %>
#   <% end %>
#
module ReaderModeHelper
  # Wrapper div that scopes the Stimulus controller.
  def reader_mode(classes: nil, &block)
    tag.div(class: classes, data: { controller: "reader-mode" }, &block)
  end

  # Icon button that opens the reader mode dialog.
  def reader_mode_button(tooltip: "Reader mode")
    tooltip(tooltip) do
      tag.button(
        icon(:arrows_pointing_out, classes: "h-4 w-4"),
        type: "button",
        class: "link-icon",
        data: { action: "reader-mode#open" }
      )
    end
  end

  # Full-page <dialog> overlay with sticky header and scrollable content.
  def reader_mode_dialog(title:, &block)
    body = capture(&block)

    tag.dialog(
      class: "reader-mode-dialog m-0 h-full w-full max-h-full max-w-full " \
             "bg-white dark:bg-zinc-900 p-0 overflow-y-auto " \
             "backdrop:bg-white dark:backdrop:bg-zinc-900",
      data: {
        reader_mode_target: "dialog",
        action: "cancel->reader-mode#close"
      }
    ) do
      # Sticky header bar
      header = tag.div(
        class: "sticky top-0 z-10 flex items-center justify-between " \
               "px-6 py-3 bg-white dark:bg-zinc-900 " \
               "border-b border-zinc-200 dark:border-zinc-700"
      ) do
        tag.h2(title, class: "text-base font-semibold text-zinc-900 dark:text-zinc-100") +
        tag.button(
          icon(:x_mark, classes: "h-5 w-5"),
          type: "button",
          class: "link-icon",
          data: { action: "reader-mode#close" }
        )
      end

      # Scrollable content area
      content = tag.div(class: "mx-auto max-w-prose px-6 py-8 reader-mode-body") do
        body
      end

      header + content
    end
  end
end
