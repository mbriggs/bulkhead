import { Controller } from "@hotwired/stimulus"

// Truncates text with an inline "more…" / "less…" toggle.
// When truncated, "more…" overlays the end of the last visible line.
// When expanded, "less…" appears inline after the full text.
//
// Usage:
//   <div data-controller="truncate" data-truncate-lines-value="3" class="relative">
//     <p data-truncate-target="content" class="whitespace-pre-wrap line-clamp-3">Long text…</p>
//     <button data-truncate-target="toggle" data-action="truncate#toggle"
//       class="hidden absolute bottom-0 right-0 ... bg-gradient-to-l ...">more…</button>
//   </div>
export default class extends Controller {
  static targets = ["content", "toggle"]
  static values = { lines: { type: Number, default: 3 } }

  connect() {
    requestAnimationFrame(() => this.#updateVisibility())
  }

  toggle() {
    const clampClass = `line-clamp-${this.linesValue}`
    const wasClamped = this.contentTarget.classList.contains(clampClass)

    if (wasClamped) {
      this.contentTarget.classList.remove(clampClass)
      this.#showInline()
    } else {
      this.contentTarget.classList.add(clampClass)
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
    btn.classList.add("absolute", "bottom-0", "right-0")
    btn.classList.remove("relative", "mt-1")
    btn.classList.add("bg-gradient-to-l", "from-white", "from-60%", "via-white",
      "dark:from-zinc-800", "dark:via-zinc-800", "to-transparent", "pl-8", "pr-0.5")
  }

  // Position inline after the expanded text
  #showInline() {
    const btn = this.toggleTarget
    btn.textContent = "less\u2026"
    btn.classList.remove("absolute", "bottom-0", "right-0")
    btn.classList.add("relative", "mt-1")
    btn.classList.remove("bg-gradient-to-l", "from-white", "from-60%", "via-white",
      "dark:from-zinc-800", "dark:via-zinc-800", "to-transparent", "pl-8", "pr-0.5")
  }
}
