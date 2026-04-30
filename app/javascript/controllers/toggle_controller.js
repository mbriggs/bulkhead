import { Controller } from "@hotwired/stimulus"

// Handles toggle switch form inputs
export default class extends Controller {
  static targets = ["checkbox", "switch", "slider"]

  connect() {
    this.update()
  }

  toggle() {
    this.checkboxTarget.checked = !this.checkboxTarget.checked
    this.checkboxTarget.dispatchEvent(new Event('change', { bubbles: true }))
    this.update()
  }

  update() {
    const checked = this.checkboxTarget.checked
    this.switchTarget.setAttribute("aria-checked", checked.toString())
  }
}
