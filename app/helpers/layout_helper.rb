module LayoutHelper
  # Active when the current request path equals `path` (when `exact: true`) or
  # starts with it (default — useful for nested admin sections like /admin/jobs
  # /admin/jobs/123). Pass `exact: true` for index-style links whose path is a
  # prefix of sibling routes (e.g. an "Overview" link at /kitchen_sink).
  def menu_item(icon_name, text, path, inactive: nil, exact: false)
    active = exact ? request.fullpath == path : request.fullpath.starts_with?(path)
    active = false if inactive && request.fullpath.match?(inactive)

    classes = classnames("shell-nav-item", { "active" => active })
    icon_classes = "shell-nav-icon"

    link_opts = { class: classes }
    link_opts[:"aria-current"] = "page" if active

    link_to path, **link_opts do
      icon(icon_name, classes: icon_classes) + content_tag(:span, text)
    end
  end

  def shell(&block)
    content_tag(:div, class: "shell", data: { controller: "shell" }, &block)
  end

  # Inline script that applies the saved theme class before CSS paints.
  def theme_bootstrap_script(storage_key: "theme", class_name: "is-dark")
    script = <<~JS
      (function () {
        var saved = localStorage.getItem("#{j(storage_key)}");
        var prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
        if (saved === "dark" || (!saved && prefersDark)) {
          document.documentElement.classList.add("#{j(class_name)}");
        }
      })();
    JS

    tag.script(script.html_safe, nonce: content_security_policy_nonce)
  end

  def shell_sidebar(brand:, brand_href: "/", brand_icon: :rectangle_stack, actions: nil, footer: nil, &block)
    content_tag(:aside, class: "shell-sidebar", data: { shell_target: "sidebar" }) do
      header = content_tag(:div, class: "shell-sidebar-header") do
        brand_link = link_to(brand_href, class: "shell-sidebar-header-link") do
          icon(brand_icon, classes: "shell-nav-icon") +
            content_tag(:span, brand, class: "shell-sidebar-brand")
        end
        brand_link + (actions || "".html_safe)
      end
      nav = content_tag(:nav, class: "shell-sidebar-nav", &block)
      footer_node = footer ? content_tag(:footer, footer, class: "shell-sidebar-footer") : "".html_safe
      header + nav + footer_node
    end
  end

  def shell_content(&block)
    content_tag(:main, class: "shell-content") do
      content_tag(:div, class: "shell-content-inner", &block)
    end
  end

  def shell_nav_section(label)
    content_tag(:div, label, class: "shell-sidebar-section-label")
  end
end
