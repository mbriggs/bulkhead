import { Controller } from "@hotwired/stimulus"

// Handles toggle switch form inputs
export default class extends Controller {
  static targets = ["checkbox", "switch", "slider"]
  static values = {
    translateClass: { type: String, default: "translate-x-4" }
  }

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

    if (checked) {
      this.switchTarget.classList.remove("bg-zinc-200", "dark:bg-zinc-700")
      this.switchTarget.classList.add("bg-primary-600", "dark:bg-primary-500")
      this.sliderTarget.classList.remove("translate-x-0")
      this.sliderTarget.classList.add(this.translateClassValue)
    } else {
      this.switchTarget.classList.add("bg-zinc-200", "dark:bg-zinc-700")
      this.switchTarget.classList.remove("bg-primary-600", "dark:bg-primary-500")
      this.sliderTarget.classList.add("translate-x-0")
      this.sliderTarget.classList.remove(this.translateClassValue)
    }
  }
}
