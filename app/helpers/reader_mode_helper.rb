# Helpers for a full-page reading overlay using native <dialog>.
#
# The dialog has its own typography optimized for prose; size adjustment is
# left to native browser zoom.
#
#   <%= reader_mode do %>
#     <%= reader_mode_button(tooltip: "Expand") %>
#     <%= reader_mode_dialog(title: "Implementation Plan") do %>
#       <%= render_markdown(text) %>
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
        icon(:arrows_pointing_out, classes: "reader-mode-button-icon"),
        type: "button",
        class: "link-icon",
        data: { action: "reader-mode#open" }
      )
    end
  end

  # Full-page <dialog> overlay with a sticky header and scrollable body.
  def reader_mode_dialog(title:, &block)
    body = capture(&block)

    tag.dialog(
      class: "reader-mode-dialog",
      data: {
        reader_mode_target: "dialog",
        action: "cancel->reader-mode#close"
      }
    ) do
      header = tag.div(class: "reader-mode-header") do
        tag.h2(title, class: "reader-mode-title") +
          tag.button(
            icon(:x_mark, classes: "reader-mode-close-icon"),
            type: "button",
            class: "link-icon",
            "aria-label": "Close",
            data: { action: "reader-mode#close" }
          )
      end

      content = tag.div(class: "reader-mode-body") { body }

      header + content
    end
  end
end
