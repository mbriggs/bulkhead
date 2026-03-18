module ModalHelper
  # Generate the content wrapper ID for a given modal ID
  # This ensures consistency between the helper and ModalSubmittable concern
  def modal_content_id(modal_id)
    "#{modal_id}-content"
  end

  # Just the modal dialog without a trigger
  # Can accept either a block for content OR a partial path, not both
  # size: :md (default), :wide, :full
  def modal_dialog(id:, title:, partial: nil, locals: {}, size: :md, header_actions: nil, &block)
    if partial && block_given?
      raise ArgumentError, "modal_dialog accepts either a partial or a block, not both"
    end

    if partial
      # Render the specified partial inside the content wrapper
      # This enables consistent error handling with Turbo Streams
      content = render(partial: partial, locals: locals)
    elsif block_given?
      # Use the provided block
      content = capture(&block)
    else
      raise ArgumentError, "modal_dialog requires either a partial or a block"
    end

    render "shared/modals/dialog",
           id: id,
           title: title,
           content: content,
           partial_path: partial,
           partial_locals: locals,
           size_class: modal_size_class(size),
           header_actions: header_actions
  end

  # Modal header/chrome with title and close button
  def modal_chrome(title, &)
    render("shared/modals/chrome", title: title, &)
  end

  # Wrapper for co-locating modal trigger and dialog
  def modal_wrapper(tag_name: :div, classes: nil, close_on_submit: true, &)
    data_attrs = {
      controller: "modal",
      modal_close_on_submit_value: close_on_submit
    }

    tag.send(tag_name, data: data_attrs, class: classes, &)
  end

  # Simple trigger for opening a modal (must be inside modal_wrapper)
  def modal_open_button(text = nil, options: {}, &)
    content = text || capture(&)

    # Add default link-like styling if no class is provided
    default_classes = "link-title"
    existing_classes = options[:class] || ""
    classes = existing_classes.presence || default_classes
    options = options.merge(
      class: classes,
      data: (options[:data] || {}).merge(
        action: "click->modal#open",
      ),
    )

    options[:"aria-haspopup"] = "dialog"
    tag.button(**options, type: "button") { content }
  end

  private

  # Tailwind max-width class for the modal content panel
  def modal_size_class(size)
    case size.to_sym
    when :wide then "max-w-3xl"
    when :full then "max-w-[90vw] max-h-[85vh]"
    else "max-w-lg"
    end
  end
end
