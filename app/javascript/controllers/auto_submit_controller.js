import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit(event) {
    const form = event.target.closest("form")
    if (form) form.requestSubmit()
  }

  input(event) {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => {
      this.submit(event)
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
