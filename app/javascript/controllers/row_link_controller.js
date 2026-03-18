import { Controller } from "@hotwired/stimulus"

// Makes table rows clickable as links.
// Supports cmd/ctrl+click for new tab and preserves native link clicks within the row.
//
// Usage:
//   <tr data-controller="row-link" data-row-link-href-value="/path">
export default class extends Controller {
  static values = { href: String }

  connect() {
    this.element.style.cursor = "pointer"
    this.element.setAttribute("role", "link")
    this.element.setAttribute("tabindex", "0")
  }

  click(event) {
    // Don't intercept clicks on actual links or buttons within the row
    if (event.target.closest("a, button")) return

    if (event.metaKey || event.ctrlKey) {
      window.open(this.hrefValue, "_blank")
    } else {
      Turbo.visit(this.hrefValue)
    }
  }

  keydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      Turbo.visit(this.hrefValue)
    }
  }
}
