import { Controller } from "@hotwired/stimulus"

// Kitchen-sink-only helper that drives the log_tail demo. Each `append`
// click adds a fresh row into the container, which the surrounding
// log-tail controller pins on if the operator is near the bottom.
export default class extends Controller {
  static targets = ["list"]
  static values = { count: { type: Number, default: 0 } }

  append() {
    this.countValue += 1
    const row = document.createElement("div")
    row.className = "demo-log-row"
    row.dataset.eventId = `demo-${this.countValue}`
    row.textContent = `${new Date().toLocaleTimeString()} — log row ${this.countValue}`
    this.listTarget.appendChild(row)
  }
}
