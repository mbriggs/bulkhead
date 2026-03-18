import { Controller } from "@hotwired/stimulus"

// Handles segmented control inputs — a pill bar of mutually exclusive options
// backed by hidden radio inputs.
export default class extends Controller {
  static targets = ["radio", "option"]
  static classes = ["active", "inactive"]

  connect() {
    this.update()
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const radio = this.radioTargets.find(r => r.value === value)
    if (radio && !radio.checked) {
      radio.checked = true
      radio.dispatchEvent(new Event("change", { bubbles: true }))
      this.update()
    }
  }

  update() {
    const selected = this.radioTargets.find(r => r.checked)?.value

    this.optionTargets.forEach(button => {
      const isActive = button.dataset.value === selected
      button.setAttribute("aria-checked", isActive.toString())

      if (isActive) {
        this.inactiveClasses.forEach(c => button.classList.remove(c))
        this.activeClasses.forEach(c => button.classList.add(c))
      } else {
        this.activeClasses.forEach(c => button.classList.remove(c))
        this.inactiveClasses.forEach(c => button.classList.add(c))
      }
    })
  }
}
