import { Controller } from "@hotwired/stimulus"

// Pins the page to the bottom as new rows append into this controller's
// element, but only when the operator was already at (or near) the
// bottom of the page. If they've scrolled up to read history, new
// appends leave their position alone.
//
// The element this controller is attached to (a turbo-frame) doesn't
// scroll — the page does — so the scroll state is read from the window
// while the mutation observer watches the frame for appended children.
//
//   <turbo-frame ... data-controller="log-tail">
//     <div class="job-event-row">…</div>
//     <div class="job-event-row">…</div>
//   </turbo-frame>
const STICK_THRESHOLD_PX = 80

export default class extends Controller {
  static values = {
    active: { type: Boolean, default: true }
  }

  connect() {
    this.stickToBottom = this.activeValue
    if (this.activeValue) this.scrollToBottom()

    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })

    this.observer = new MutationObserver(this.handleMutation.bind(this))
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    this.stickToBottom = this.isNearBottom()
  }

  handleMutation() {
    if (this.stickToBottom) this.scrollToBottom()
  }

  isNearBottom() {
    const scroller = document.scrollingElement || document.documentElement
    const { scrollTop, scrollHeight, clientHeight } = scroller
    return scrollHeight - (scrollTop + clientHeight) <= STICK_THRESHOLD_PX
  }

  scrollToBottom() {
    const scroller = document.scrollingElement || document.documentElement
    scroller.scrollTop = scroller.scrollHeight
  }
}
