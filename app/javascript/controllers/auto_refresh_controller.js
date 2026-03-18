import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 30000 }, // 30 seconds
    src: String
  }

  connect() {
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.intervalValue)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  async refresh() {
    const frame = this.element.querySelector("turbo-frame")
    if (frame && this.hasSrcValue) {
      frame.src = this.srcValue
    }
  }
}
