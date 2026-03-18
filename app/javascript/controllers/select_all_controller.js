import { Controller } from "@hotwired/stimulus"

/**
 * Select All Controller
 *
 * Purpose
 * - Provides generic "Select All / Deselect All" behavior for a set of checkboxes.
 * - Optional grouping: buttons and checkboxes can share a data attribute (default
 *   `data-group`) to scope toggles per group; if absent, applies to all.
 *
 * Targets
 * - checkbox, counter (optional), selectAllButton
 *
 * Values
 * - groupAttribute: which data attribute marks groups (default: "group")
 * - selectText / deselectText: toggle labels (defaults provided)
 */
export default class extends Controller {
  static targets = ["checkbox", "counter", "selectAllButton"]
  static values = {
    groupAttribute: { type: String, default: "group" },
    selectText: { type: String, default: "Select All" },
    deselectText: { type: String, default: "Deselect All" }
  }

  connect() {
    this.updateCounter()
    this.updateSelectAllButtons()
  }

  // Toggle all checkboxes for a given group (or all if no group specified)
  toggleGroup(event) {
    const groupKey = this.groupAttributeValue
    const groupId = event.currentTarget.dataset[groupKey]

    const checkboxes = this.checkboxTargets.filter(cb => {
      if (cb.disabled) return false
      const cbGroup = cb.dataset[groupKey]
      return groupId === undefined || cbGroup === groupId
    })

    const allChecked = checkboxes.every(cb => cb.checked)
    checkboxes.forEach(cb => {
      cb.checked = !allChecked
      // Notify any listeners that checkbox state changed
      cb.dispatchEvent(new Event('change', { bubbles: true }))
    })

    // Update button text for the clicked button
    event.currentTarget.textContent = allChecked ? this.selectTextValue : this.deselectTextValue
    event.currentTarget.setAttribute('aria-pressed', (!allChecked).toString())

    this.updateCounter()
    this.updateSelectAllButtons()
  }

  // Update counter when an individual checkbox changes
  checkboxChanged() {
    this.updateCounter()
    this.updateSelectAllButtons()
  }

  updateCounter() {
    if (!this.hasCounterTarget) return
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked && !cb.disabled).length
    this.counterTarget.textContent = checkedCount
  }

  updateSelectAllButtons() {
    if (!this.hasSelectAllButtonTarget) return
    const groupKey = this.groupAttributeValue

    this.selectAllButtonTargets.forEach(button => {
      const groupId = button.dataset[groupKey]
      const groupCheckboxes = this.checkboxTargets.filter(cb => {
        if (cb.disabled) return false
        const cbGroup = cb.dataset[groupKey]
        return groupId === undefined || cbGroup === groupId
      })
      if (groupCheckboxes.length === 0) return
      const allChecked = groupCheckboxes.every(cb => cb.checked)
      button.textContent = allChecked ? this.deselectTextValue : this.selectTextValue
      button.setAttribute('aria-pressed', allChecked.toString())
    })
  }

  getSelectedValues() {
    return this.checkboxTargets
      .filter(cb => cb.checked && !cb.disabled)
      .map(cb => cb.value)
  }

  hasSelection() {
    return this.checkboxTargets.some(cb => cb.checked && !cb.disabled)
  }
}
