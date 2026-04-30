import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "placeholder", "inner"]
  static values = {
    scrollThreshold: { type: Number, default: 50 }
  }

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })

    // Create placeholder element
    this.placeholder = document.createElement("div")
    this.placeholder.style.display = "none"
    this.headerTarget.parentNode.insertBefore(this.placeholder, this.headerTarget)

    // Set initial state
    this.handleScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.removeChild(this.placeholder)
    }
  }

  handleScroll() {
    if (!this.hasHeaderTarget) return

    const isScrolled = window.scrollY > this.scrollThresholdValue
    if (isScrolled === this.isSticky) return

    // Capture height before mutating layout — once fixed, offsetHeight may change.
    if (isScrolled) {
      this.placeholder.style.height = `${this.headerTarget.offsetHeight}px`
    }

    this.headerTarget.classList.toggle("fixed", isScrolled)
    if (this.hasInnerTarget) this.innerTarget.classList.toggle("scrolled", isScrolled)
    this.placeholder.style.display = isScrolled ? "block" : "none"

    this.isSticky = isScrolled
  }
}
