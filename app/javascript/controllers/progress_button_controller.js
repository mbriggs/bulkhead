import { Controller } from "@hotwired/stimulus"

/**
 * Progress Button Controller
 *
 * Purpose
 * - Generic UI behavior for long-running submits: disable button, show spinner,
 *   optionally display a percent complete as the server streams progress.
 * - Validation is optional via `requiresSelectorValue` to ensure some selection
 *   is present before submitting (e.g., checked checkboxes).
 *
 * Targets
 * - submitButton, buttonText, spinner, progressText, error (optional inline error)
 *
 * Values
 * - requiresSelector: CSS selector for required nodes (e.g., "input[type=checkbox]:checked")
 * - requiresMessage: message to show/raise when requirement is not met
 * - workingText: text shown while submit in progress
 * - successText: text shown when completed (percent >= 100)
 *
 * Progress contract
 * - If the server sends Turbo Streams that include `data-progress='{"percent":42}'`,
 *   this controller will update the progressText target automatically while active.
 * - Callers may also invoke `updateProgress(percent, message)` manually (e.g., via
 *   a custom Turbo Stream action that targets an element this controller manages).
 *
 * Turbo integration tips
 * - Turbo supports `data-turbo-submits-with` on the submitter to change text while
 *   submitting; you can use it instead of or alongside `workingText`.
 * - This controller listens to `turbo:submit-end` to ensure UI is re-enabled even
 *   if no progress stream arrives.
 */
// Contract for progress updates:
// - Server may send Turbo Streams with <turbo-stream ... data-progress='{"percent":42,"message":"..."}'>
// - Alternatively, callers can invoke updateProgress(percent, message) manually
// This controller listens only while a job is in progress to avoid global churn.
export default class extends Controller {
  static targets = ["submitButton", "buttonText", "spinner", "progressText", "error"]
  static values = {
    requiresSelector: String,
    requiresMessage: { type: String, default: "Please select at least one item" },
    workingText: { type: String, default: "Working..." },
    successText: { type: String, default: "Done!" }
  }

  connect() {
    this.onBeforeStreamRender = null
    this.onSubmitEnd = this.handleSubmitEnd.bind(this)
    this.element.addEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  disconnect() {
    this.removeProgressListener()
    if (this.onSubmitEnd) {
      this.element.removeEventListener("turbo:submit-end", this.onSubmitEnd)
      this.onSubmitEnd = null
    }
  }

  handleSubmitStart(event) {
    // Optional: require at least one matching element (e.g., checked checkbox)
    if (this.hasRequiresSelectorValue) {
      const nodes = Array.from(this.element.querySelectorAll(this.requiresSelectorValue))
      const anySelected = nodes.some(node => {
        if (node.matches('input[type="checkbox"]')) {
          return node.checked && !node.disabled
        }
        return !node.disabled
      })
      if (!anySelected) {
        event.preventDefault()
        this.showError(this.requiresMessageValue)
        return
      }
    }

    // Clear error and show spinner
    if (this.hasErrorTarget) this.errorTarget.classList.add("hidden")
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.remove("hidden")

    // Start listening for progress only while working
    this.addProgressListener()
  }

  handleProgressUpdate(event) {
    // Look for progress data in the turbo stream
    const progressData = event.detail?.newStream?.dataset?.progress
    if (progressData && this.hasProgressTextTarget) {
      try {
        const progress = JSON.parse(progressData)
        this.updateProgress(progress.percent, progress.message)
      } catch (e) {
        console.error("[ProgressButtonController] Failed to parse progress data:", e)
      }
    }
  }

  updateProgress(percent, message = null) {
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.classList.remove("hidden")
      this.progressTextTarget.textContent = `${percent}%`
    }

    if (message && this.hasButtonTextTarget) {
      this.buttonTextTarget.textContent = message
    }

    // If complete, show success state
    if (percent >= 100) {
      this.showComplete()
    }
  }

  showComplete() {
    this.removeProgressListener()
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.add("hidden")
    if (this.hasButtonTextTarget) this.buttonTextTarget.textContent = this.successTextValue

    if (this.hasProgressTextTarget) {
      this.progressTextTarget.classList.add("hidden")
    }

    // Re-enable button after a delay
    setTimeout(() => {
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
      }
    }, 2000)
  }

  addProgressListener() {
    if (this.onBeforeStreamRender) return
    this.onBeforeStreamRender = this.handleProgressUpdate.bind(this)
    document.addEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
  }

  removeProgressListener() {
    if (!this.onBeforeStreamRender) return
    document.removeEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
    this.onBeforeStreamRender = null
  }

  showError(message) {
    if (!this.hasErrorTarget) {
      // Prefer explicit markup; raise to surface the missing target in dev
      throw new Error(message)
    }
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.errorTarget.setAttribute("role", "alert")
    this.errorTarget.focus?.()
  }

  handleSubmitEnd() {
    // Ensure UI is not left disabled if no progress stream is used
    this.removeProgressListener()
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.add("hidden")
    if (this.hasSubmitButtonTarget) this.submitButtonTarget.disabled = false
  }
}
