import { Controller } from "@hotwired/stimulus"

/**
 * Bulk Select Controller
 *
 * Manages bulk selection of items with form submission.
 * Creates hidden inputs for selected items when submitting.
 *
 * Targets:
 * - checkbox: Individual row checkboxes
 * - selectAll: Header checkbox to toggle all
 * - count: Element showing selection count
 * - submitButton: Submit button (enabled when items selected)
 * - discardButton: Optional secondary submit button
 * - form: Primary form to submit
 * - discardForm: Optional secondary form
 * - jobIds: Container for hidden inputs in primary form
 * - discardJobIds: Container for hidden inputs in secondary form
 */
export default class extends Controller {
  static targets = [
    "checkbox",
    "selectAll",
    "count",
    "submitButton",
    "discardButton",
    "form",
    "discardForm",
    "jobIds",
    "discardJobIds"
  ]

  connect() {
    this.updateUI()
  }

  toggle() {
    this.updateUI()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateUI()
  }

  updateUI() {
    const selectedIds = this.selectedIds()
    const count = selectedIds.length

    // Update count display
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
    }

    // Update select all checkbox
    if (this.hasSelectAllTarget) {
      const allChecked = count === this.checkboxTargets.length && count > 0
      const someChecked = count > 0 && count < this.checkboxTargets.length
      this.selectAllTarget.checked = allChecked
      this.selectAllTarget.indeterminate = someChecked
    }

    // Enable/disable submit buttons
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = count === 0
    }
    if (this.hasDiscardButtonTarget) {
      this.discardButtonTarget.disabled = count === 0
    }

    // Update hidden inputs
    if (this.hasJobIdsTarget) {
      this.updateHiddenInputs(this.jobIdsTarget, selectedIds)
    }
    if (this.hasDiscardJobIdsTarget) {
      this.updateHiddenInputs(this.discardJobIdsTarget, selectedIds)
    }
  }

  updateHiddenInputs(container, ids) {
    if (!container) return
    container.innerHTML = ""
    ids.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "job_ids[]"
      input.value = id
      container.appendChild(input)
    })
  }

  selectedIds() {
    return this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }
}
