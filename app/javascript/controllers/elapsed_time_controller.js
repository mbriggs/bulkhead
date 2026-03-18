import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    startedAt: String
  }

  connect() {
    this.update()
    this.timer = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  update() {
    if (!this.hasStartedAtValue) return

    const started = new Date(this.startedAtValue)
    const now = new Date()
    const elapsed = Math.floor((now - started) / 1000)

    this.element.textContent = this.formatDuration(elapsed)
  }

  formatDuration(totalSeconds) {
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    if (hours > 0) {
      return `${hours}h ${minutes}m ${seconds}s`
    } else if (minutes > 0) {
      return `${minutes}m ${seconds}s`
    } else {
      return `${seconds}s`
    }
  }
}
