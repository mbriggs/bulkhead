import { Controller } from "@hotwired/stimulus"

// Tiny hover-card. The trigger fires `open` on mouseenter/focus and
// `close` on mouseleave/blur; the popover shows when [data-open]
// is set. CSS owns the transitions and the layout.
export default class extends Controller {
  static targets = ["popover"]

  open() {
    if (!this.hasPopoverTarget) return
    this.popoverTarget.dataset.open = "true"
  }

  close() {
    if (!this.hasPopoverTarget) return
    delete this.popoverTarget.dataset.open
  }
}
