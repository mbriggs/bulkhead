import { Controller } from "@hotwired/stimulus"

// Pill-bar tabs that toggle panel visibility. Follows the same pattern as
// segmented_control_controller. Optionally persists the active tab in the URL
// query string (set data-tabs-persist-value="true" to enable).
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { persist: { type: Boolean, default: false } }

  connect() {
    const initial = this.persistValue ? this.#tabFromURL() : null
    const tab = initial
      ? this.tabTargets.find(t => t.dataset.tab === initial)
      : this.tabTargets[0]

    this.select({ currentTarget: tab || this.tabTargets[0] })

    this.resizeObserver = new ResizeObserver(() => this.#updateIndicator())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }

  select(event) {
    if (event.currentTarget.getAttribute("aria-selected") === "true") return

    const selectedTab = event.currentTarget.dataset.tab

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === selectedTab
      tab.setAttribute("aria-selected", isActive.toString())
    })

    this.panelTargets.forEach(panel => {
      panel.hidden = panel.dataset.tab !== selectedTab
    })

    this.#updateIndicator()

    if (this.persistValue) this.#updateURL(selectedTab)
  }

  #updateIndicator() {
    requestAnimationFrame(() => {
      const list = this.element.querySelector(".tabs-list") || this.element
      const active = this.tabTargets.find(t => t.getAttribute("aria-selected") === "true")
      if (!active) return
      list.style.setProperty("--tab-indicator-left", `${active.offsetLeft}px`)
      list.style.setProperty("--tab-indicator-width", `${active.offsetWidth}px`)
    })
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
