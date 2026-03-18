import { Controller } from "@hotwired/stimulus"

// Pill-bar tabs that toggle panel visibility. Follows the same pattern as
// segmented_control_controller. Optionally persists the active tab in the URL
// query string (set data-tabs-persist-value="true" to enable).
export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]
  static values = { persist: { type: Boolean, default: false } }

  connect() {
    const initial = this.persistValue ? this.#tabFromURL() : null
    const tab = initial
      ? this.tabTargets.find(t => t.dataset.tab === initial)
      : this.tabTargets[0]

    this.select({ currentTarget: tab || this.tabTargets[0] })
  }

  select(event) {
    const selectedTab = event.currentTarget.dataset.tab

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === selectedTab
      tab.setAttribute("aria-selected", isActive.toString())

      if (isActive) {
        this.inactiveClasses.forEach(c => tab.classList.remove(c))
        this.activeClasses.forEach(c => tab.classList.add(c))
      } else {
        this.activeClasses.forEach(c => tab.classList.remove(c))
        this.inactiveClasses.forEach(c => tab.classList.add(c))
      }
    })

    this.panelTargets.forEach(panel => {
      panel.hidden = panel.dataset.tab !== selectedTab
    })

    if (this.persistValue) this.#updateURL(selectedTab)
  }

  #tabFromURL() {
    return new URLSearchParams(window.location.search).get("tab")
  }

  #updateURL(tab) {
    const url = new URL(window.location)
    url.searchParams.set("tab", tab)
    history.replaceState(null, "", url)
  }
}
