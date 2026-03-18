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
    const scrollPosition = window.scrollY
    const isScrolled = scrollPosition > this.scrollThresholdValue

    if (this.hasHeaderTarget) {
      if (isScrolled && !this.isSticky) {
        // Store height before making fixed
        const headerHeight = this.headerTarget.offsetHeight

        // When scrolled, make header sticky at the top
        // Important: Add lg:left-72 to respect sidebar width on desktop
        this.headerTarget.classList.add("fixed", "top-12", "lg:top-0", "left-0", "right-0", "lg:left-72", "z-30", "shadow-lg", "transition-all", "duration-300")
        this.headerTarget.classList.remove("relative")

        // Change background to darker shade
        const innerDiv = this.hasInnerTarget ? this.innerTarget : null
        if (innerDiv) {
          innerDiv.classList.add("bg-zinc-50", "dark:bg-zinc-900")
        }

        // Show placeholder to prevent content jump
        this.placeholder.style.height = `${headerHeight}px`
        this.placeholder.style.display = "block"

        this.isSticky = true
      } else if (!isScrolled && this.isSticky) {
        // When at top, remove sticky behavior
        this.headerTarget.classList.remove("fixed", "top-12", "lg:top-0", "left-0", "right-0", "lg:left-72", "z-30", "shadow-lg")
        this.headerTarget.classList.add("relative")

        // Remove background changes
        const innerDiv = this.hasInnerTarget ? this.innerTarget : null
        if (innerDiv) {
          innerDiv.classList.remove("bg-zinc-50", "dark:bg-zinc-900")
        }

        // Hide placeholder
        this.placeholder.style.display = "none"

        this.isSticky = false
      }
    }
  }
}
