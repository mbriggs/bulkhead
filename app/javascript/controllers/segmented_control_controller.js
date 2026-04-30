import { Controller } from "@hotwired/stimulus"

// Handles segmented control inputs — a pill bar of mutually exclusive options
// backed by hidden radio inputs.
export default class extends Controller {
  static targets = ["radio", "option"]

  connect() {
    this.update()

    this.resizeObserver = new ResizeObserver(() => this.#updateIndicator())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }

  select(event) {
    if (event.currentTarget.getAttribute("aria-checked") === "true") return
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
    })

    this.#updateIndicator()
  }

  #updateIndicator() {
    requestAnimationFrame(() => {
      const track = this.element.querySelector(".segmented") || this.element
      const active = this.optionTargets.find(o => o.getAttribute("aria-checked") === "true")
      if (!active) return
      track.style.setProperty("--segmented-indicator-left", `${active.offsetLeft}px`)
      track.style.setProperty("--segmented-indicator-width", `${active.offsetWidth}px`)
    })
  }
}
