import { Controller } from "@hotwired/stimulus"

// Auto-injects a copy-to-clipboard button on every <pre> element inside
// rendered markdown prose. Wraps each <pre> in a relative container and
// positions the button in the top-right corner, visible on hover.
//
//   <div data-controller="code-block-copy">
//     <pre>...</pre>   <!-- button injected automatically -->
//   </div>
//
export default class extends Controller {
  connect() {
    this.wrappers = []

    this.element.querySelectorAll("pre").forEach((pre) => {
      if (pre.parentElement?.classList.contains("code-block-wrapper")) return

      const wrapper = document.createElement("div")
      wrapper.className = "code-block-wrapper relative group/code"
      pre.parentNode.insertBefore(wrapper, pre)
      wrapper.appendChild(pre)

      const btn = document.createElement("button")
      btn.type = "button"
      btn.className =
        "absolute top-2 right-2 p-1.5 rounded-md " +
        "bg-zinc-700/60 text-zinc-300 hover:bg-zinc-600 hover:text-zinc-100 " +
        "opacity-0 group-hover/code:opacity-100 transition-opacity " +
        "cursor-pointer text-xs leading-none"
      btn.setAttribute("aria-label", "Copy code")
      btn.innerHTML = this.copyIconSvg
      btn.addEventListener("click", () => this.copy(pre, btn))
      wrapper.appendChild(btn)

      this.wrappers.push(wrapper)
    })
  }

  disconnect() {
    this.wrappers?.forEach((wrapper) => {
      const pre = wrapper.querySelector("pre")
      if (pre && wrapper.parentNode) {
        wrapper.parentNode.insertBefore(pre, wrapper)
        wrapper.remove()
      }
    })
    this.wrappers = []
  }

  async copy(pre, btn) {
    await navigator.clipboard.writeText(pre.textContent)
    const original = btn.innerHTML
    btn.innerHTML = '<span class="text-[10px] font-medium px-0.5">Copied!</span>'
    setTimeout(() => { btn.innerHTML = original }, 1500)
  }

  // Heroicon mini clipboard-document (16x16).
  get copyIconSvg() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" class="w-3.5 h-3.5">
      <path fill-rule="evenodd" d="M10.986 3H12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h1.014A2.25 2.25 0 0 1 7.25 1h1.5a2.25 2.25 0 0 1 2.236 2ZM9.5 4v-.75a.75.75 0 0 0-.75-.75h-1.5a.75.75 0 0 0-.75.75V4h3Z" clip-rule="evenodd"/>
    </svg>`
  }
}
