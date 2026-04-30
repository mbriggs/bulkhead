import { Controller } from "@hotwired/stimulus"

// Truncates text with an inline "more…" / "less…" toggle.
// When truncated, "more…" overlays the end of the last visible line.
// When expanded, "less…" appears inline after the full text.
//
// Usage:
//   <div data-controller="truncate" data-truncate-lines-value="3" class="truncate">
//     <p data-truncate-target="content" class="truncate-text line-clamp"
//        style="--bulkhead-line-clamp: 3">Long text…</p>
//     <button data-truncate-target="toggle" data-action="truncate#toggle"
//       class="hidden truncate-toggle overlay">more…</button>
//   </div>
export default class extends Controller {
  static targets = ["content", "toggle"]
  static values = { lines: { type: Number, default: 3 } }

  connect() {
    requestAnimationFrame(() => this.#updateVisibility())
  }

  toggle() {
    const wasClamped = this.contentTarget.classList.contains("line-clamp")

    if (wasClamped) {
      this.contentTarget.classList.remove("line-clamp")
      this.#showInline()
    } else {
      this.contentTarget.classList.add("line-clamp")
      this.#showOverlay()
    }
  }

  // Only show the toggle when content actually overflows
  #updateVisibility() {
    const el = this.contentTarget
    if (el.scrollHeight > el.clientHeight) {
      this.toggleTarget.classList.remove("hidden")
    }
  }

  // Position as overlay on last line of clamped text
  #showOverlay() {
    const btn = this.toggleTarget
    btn.textContent = "more\u2026"
    btn.classList.add("overlay")
    btn.classList.remove("inline")
  }

  // Position inline after the expanded text
  #showInline() {
    const btn = this.toggleTarget
    btn.textContent = "less\u2026"
    btn.classList.add("inline")
    btn.classList.remove("overlay")
  }
}
