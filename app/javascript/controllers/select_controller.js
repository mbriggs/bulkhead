import { Controller } from "@hotwired/stimulus"

// Native select enhancements. Use combobox for searchable text-entry dropdowns.
export default class extends Controller {
  static values = {
    search: Boolean,
    submitOnSelect: Boolean
  }

  connect() {
    this._submitOnChange = this._submitOnChange.bind(this)

    if (this.submitOnSelectValue) {
      this.element.addEventListener("change", this._submitOnChange)
    }
  }

  disconnect() {
    this.element.removeEventListener("change", this._submitOnChange)
  }

  _submitOnChange() {
    const form = this.element.form || this.element.closest("form")
    if (form) form.requestSubmit()
  }
}
