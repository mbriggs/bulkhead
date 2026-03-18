module LayoutHelper
  def menu_item(icon_name, text, path, inactive: nil)
    active = request.fullpath.starts_with?(path)
    active = false if inactive && request.fullpath.match?(inactive)

    classes = classnames(
      "group flex gap-x-3 rounded-md p-2 text-sm/6 font-semibold",
      {
        "bg-zinc-800 text-white" => active,
        "text-zinc-400 hover:bg-zinc-800 hover:text-white" => !active
      }
    )

    icon_classes = classnames(
      "h-6 w-6 shrink-0",
      {
        "text-white" => active,
        "text-zinc-400 group-hover:text-white" => !active
      }
    )

    link_opts = { class: classes }
    link_opts[:"aria-current"] = "page" if active

    link_to path, **link_opts do
      icon(icon_name, classes: icon_classes) + content_tag(:span, text)
    end
  end
end
