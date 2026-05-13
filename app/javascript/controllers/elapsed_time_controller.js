import { Controller } from "@hotwired/stimulus"

// Ticks an elapsed-time label every second from a fixed start timestamp.
// Server emits the start time so the page is correct on first paint, then
// the controller updates the label without a server round-trip.
//
//   <span data-controller="elapsed-time"
//         data-elapsed-time-started-at-value="2026-04-29T12:00:00Z">
//     0s
//   </span>
//
// Tick stops automatically once the element is disconnected (e.g. when
// the surrounding turbo-frame morph-refreshes it away). Seconds are
// dropped once the elapsed time crosses the hour mark — at that scale
// they're visual noise, and the label updates each minute instead.
export default class extends Controller {
  static values = { startedAt: String }

  connect() {
    this.start = Date.parse(this.startedAtValue)
    if (Number.isNaN(this.start)) return
    this.render()
    this.interval = setInterval(() => this.render(), 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  render() {
    const ms = Date.now() - this.start
    this.element.textContent = format(ms)
  }
}

function format(ms) {
  if (ms < 0) return "0s"
  const seconds = Math.floor(ms / 1000)
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ${seconds % 60}s`
  const hours = Math.floor(minutes / 60)
  return `${hours}h ${minutes % 60}m`
}
