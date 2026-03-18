import { Controller } from "@hotwired/stimulus"

// Simple show/hide toggle for disclosure patterns
// Usage:
//   <div data-controller="disclosure">
//     <button data-action="disclosure#toggle" aria-expanded="false">Toggle</button>
//     <div data-disclosure-target="content" class="hidden">Content</div>
//   </div>
export default class extends Controller {
  static targets = ["content"]

  connect() {
    const trigger = this.element.querySelector("[data-action*='disclosure#toggle']")
    if (trigger && this.hasContentTarget) {
      trigger.setAttribute("aria-expanded", (!this.contentTarget.classList.contains("hidden")).toString())
      if (this.contentTarget.id) {
        trigger.setAttribute("aria-controls", this.contentTarget.id)
      }
    }
  }

  toggle() {
    const isHidden = this.contentTarget.classList.toggle("hidden")
    const trigger = this.element.querySelector("[data-action*='disclosure#toggle']")
    if (trigger) {
      trigger.setAttribute("aria-expanded", (!isHidden).toString())
      const showText = trigger.dataset.disclosureShowText
      const hideText = trigger.dataset.disclosureHideText
      if (showText && hideText) {
        trigger.textContent = isHidden ? showText : hideText
      }
    }
  }
}
