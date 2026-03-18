import { Controller } from "@hotwired/stimulus"

// Full-page reading overlay using native <dialog>.
// Provides showModal() for free Escape-key dismiss and focus trapping.
//
//   <div data-controller="reader-mode">
//     <button data-action="reader-mode#open">Expand</button>
//     <dialog data-reader-mode-target="dialog">...</dialog>
//   </div>
//
export default class extends Controller {
  static targets = ["dialog"]

  disconnect() {
    document.documentElement.classList.remove("overflow-hidden")
  }

  open(event) {
    event.preventDefault()
    this.previousFocus = document.activeElement
    document.documentElement.classList.add("overflow-hidden")
    this.dialogTarget.showModal()
  }

  // Handles both the X button and native Escape-key dismiss.
  // Escape fires cancel before the browser auto-closes; preventDefault()
  // stops that so all exits go through this single codepath.
  close(event) {
    event?.preventDefault()
    this.dialogTarget.close()
    document.documentElement.classList.remove("overflow-hidden")
    this.previousFocus?.focus()
  }
}
