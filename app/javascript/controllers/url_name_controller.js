import { Controller } from "@hotwired/stimulus"

// Extracts the last path segment from a URL field and fills a name field.
// Only auto-fills when the name field is empty or was previously auto-filled.
//
//   <div data-controller="url-name">
//     <input data-url-name-target="url" data-action="input->url-name#extract">
//     <input data-url-name-target="name">
//   </div>
export default class extends Controller {
  static targets = ["url", "name"]

  connect() {
    this._autoFilled = !this.nameTarget.value
  }

  extract() {
    if (!this._autoFilled) return

    const value = this.urlTarget.value.replace(/\/+$/, "")
    const lastSegment = value.split("/").pop() || ""
    this.nameTarget.value = lastSegment
  }

  // Stop auto-filling once the user manually edits the name field.
  manualEdit() {
    this._autoFilled = false
  }
}
