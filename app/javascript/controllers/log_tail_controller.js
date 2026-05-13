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
//
// Tail mode is exited on any upward scroll intent (wheel deltaY < 0,
// or a scroll event whose scrollTop decreased) rather than waiting
// until the operator has crossed the bottom threshold. A
// scroll-event-only approach loses the race when an append fires
// between the user's wheel input and the resulting scroll event: the
// mutation observer snaps to bottom because stickToBottom hasn't yet
// been cleared. Wheel and direction tracking surface intent first.
const STICK_THRESHOLD_PX = 80

export default class extends Controller {
  static values = {
    active: { type: Boolean, default: true }
  }

  connect() {
    this.stickToBottom = this.activeValue
    if (this.activeValue) this.scrollToBottom()
    this.lastScrollTop = this.scroller().scrollTop

    this.handleScroll = this.handleScroll.bind(this)
    this.handleWheel = this.handleWheel.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
    window.addEventListener("wheel", this.handleWheel, { passive: true })

    this.observer = new MutationObserver(this.handleMutation.bind(this))
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
    window.removeEventListener("scroll", this.handleScroll)
    window.removeEventListener("wheel", this.handleWheel)
  }

  handleScroll() {
    const scrollTop = this.scroller().scrollTop
    if (scrollTop < this.lastScrollTop) {
      this.stickToBottom = false
    } else if (this.isNearBottom()) {
      this.stickToBottom = true
    }
    this.lastScrollTop = scrollTop
  }

  handleWheel(event) {
    if (event.deltaY < 0) this.stickToBottom = false
  }

  handleMutation() {
    if (this.stickToBottom) this.scrollToBottom()
  }

  isNearBottom() {
    const { scrollTop, scrollHeight, clientHeight } = this.scroller()
    return scrollHeight - (scrollTop + clientHeight) <= STICK_THRESHOLD_PX
  }

  scrollToBottom() {
    const scroller = this.scroller()
    scroller.scrollTop = scroller.scrollHeight
    this.lastScrollTop = scroller.scrollTop
  }

  scroller() {
    return document.scrollingElement || document.documentElement
  }
}
