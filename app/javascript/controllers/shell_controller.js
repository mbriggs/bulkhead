import { Controller } from "@hotwired/stimulus"

// Toggles the mobile sidebar drawer. The hamburger button has
// `data-action="shell#toggle"`, the sidebar has `data-shell-target="sidebar"`,
// and the optional scrim has `data-shell-target="scrim"`.
export default class extends Controller {
  static targets = ["sidebar", "scrim"]

  toggle() {
    const open = !this.sidebarTarget.classList.contains("open")
    this.sidebarTarget.classList.toggle("open", open)
    if (this.hasScrimTarget) this.scrimTarget.classList.toggle("open", open)
    document.body.style.overflow = open ? "hidden" : ""
  }

  close() {
    this.sidebarTarget.classList.remove("open")
    if (this.hasScrimTarget) this.scrimTarget.classList.remove("open")
    document.body.style.overflow = ""
  }
}
