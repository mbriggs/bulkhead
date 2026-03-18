import { Controller } from "@hotwired/stimulus"

// Resets form on successful submission
export default class extends Controller {
  connect() {
    this.element.addEventListener('turbo:submit-end', this.handleSubmitEnd)
  }

  disconnect() {
    this.element.removeEventListener('turbo:submit-end', this.handleSubmitEnd)
  }

  handleSubmitEnd = (event) => {
    // Only reset if submission was successful
    if (event.detail.success) {
      this.element.reset()
    }
  }
}
