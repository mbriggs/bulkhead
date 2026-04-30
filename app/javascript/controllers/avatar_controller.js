import { Controller } from "@hotwired/stimulus"

// Hides the avatar `<img>` and reveals the sibling fallback element
// (located by id) when the image fails to load. Mounted on the img so the
// helper can keep img + fallback as siblings rather than wrapping them.
//
// Avoids inline `onerror=` so the helper works under a strict
// Content-Security-Policy with no `unsafe-inline`.
export default class extends Controller {
  static values = { fallbackId: String }

  connect() {
    const img = this.element
    if (img.complete && img.naturalWidth === 0) this.fail()
  }

  fail() {
    this.element.style.display = "none"
    if (this.hasFallbackIdValue) {
      const fallback = document.getElementById(this.fallbackIdValue)
      if (fallback) fallback.style.display = ""
    }
  }
}
