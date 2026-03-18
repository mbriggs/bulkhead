import { Controller } from "@hotwired/stimulus"

// Copies text content to the clipboard.
//
// Two modes:
//
// 1. Self-contained — controller wraps both trigger and source:
//
//   <div data-controller="clipboard">
//     <pre data-clipboard-target="source">content</pre>
//     <button data-action="clipboard#copy" data-clipboard-target="button">Copy</button>
//   </div>
//
// 2. Detached — button carries the text directly (for modal headers, etc.):
//
//   <button data-controller="clipboard"
//           data-clipboard-text-value="content to copy"
//           data-action="clipboard#copy">Copy</button>
//
export default class extends Controller {
  static values = { text: String }
  static targets = ["source", "button"]

  async copy() {
    const text = this.hasTextValue
      ? this.textValue
      : this.sourceTarget.textContent

    await navigator.clipboard.writeText(text)
    this.showConfirmation()
  }

  showConfirmation() {
    const btn = this.hasButtonTarget ? this.buttonTarget : this.element
    const original = btn.innerHTML
    const isIconOnly = btn.querySelector("svg") && !btn.textContent.trim()
    btn.innerHTML = isIconOnly
      ? '<span class="text-[10px] font-medium inline-flex items-center h-4">Copied!</span>'
      : "Copied!"
    setTimeout(() => { btn.innerHTML = original }, 1500)
  }
}
