import { Controller } from "@hotwired/stimulus"

// Toggles `html.is-dark` and persists the choice to localStorage.
// When no explicit override is saved, follows the OS preference and updates
// live as that preference changes. Buttons can use `data-action="theme#toggle"`.
// Optional targets: `data-theme-target="sun"` (visible in dark mode) and
// `data-theme-target="moon"` (visible in light mode) for icon swapping.
export default class extends Controller {
  static targets = ["sun", "moon"]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.osListener = () => { if (!this.savedTheme()) this.apply(this.mediaQuery.matches) }
    this.mediaQuery.addEventListener("change", this.osListener)
    // Apply the saved theme (or OS preference if none saved) on connect.
    // The host's FOUC inline script is best practice but not required —
    // without this, localStorage.theme = "dark" was being ignored.
    const saved = this.savedTheme()
    this.apply(saved ? saved === "dark" : this.mediaQuery.matches)
    this.sync()
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.osListener)
  }

  toggle() {
    const next = !this.isDark()
    localStorage.setItem("theme", next ? "dark" : "light")
    this.apply(next)
    this.sync()
  }

  apply(dark) {
    document.documentElement.classList.toggle("is-dark", dark)
  }

  isDark() {
    return document.documentElement.classList.contains("is-dark")
  }

  savedTheme() {
    const v = localStorage.getItem("theme")
    return v === "dark" || v === "light" ? v : null
  }

  sync() {
    if (this.hasSunTarget) this.sunTarget.hidden = !this.isDark()
    if (this.hasMoonTarget) this.moonTarget.hidden = this.isDark()
  }
}
