import { Controller } from "@hotwired/stimulus"

// Simple toggle that updates URL params and navigates with Turbo
export default class extends Controller {
  static values = {
    param: String  // The URL parameter name to toggle
  }

  toggle(event) {
    // Get the checkbox from the event (it could be from the checkbox or the visual toggle)
    const checkbox = this.element.querySelector('input[type="checkbox"]')
    const checked = checkbox.checked

    // Get current URL and params
    const url = new URL(window.location)

    // Update the parameter
    if (checked) {
      url.searchParams.set(this.paramValue, "true")
    } else {
      url.searchParams.delete(this.paramValue)
    }

    // Navigate with Turbo (will use morphing if enabled)
    Turbo.visit(url.toString())
  }
}
