import { Controller } from "@hotwired/stimulus"

// Updates a turbo-frame's `src` from an input's value, treated as a
// query parameter. Use for dependent selects — when the chooser changes,
// a sibling turbo-frame reloads with the new value attached.
//
//   <select data-controller="frame-src"
//           data-action="change->frame-src#update"
//           data-frame-src-url-value="/items/options"
//           data-frame-src-frame-value="item-options"
//           data-frame-src-param-value="kind">
//     ...
//   </select>
//   <turbo-frame id="item-options"></turbo-frame>
//
// `param` defaults to "value"; pass it when the receiving endpoint
// expects a more specific name.
export default class extends Controller {
  static values = { url: String, frame: String, param: { type: String, default: "value" } }

  update(event) {
    const frame = document.getElementById(this.frameValue)
    const url = new URL(this.urlValue, window.location.origin)

    url.searchParams.set(this.paramValue, event.target.value)
    frame.src = url.toString()
  }
}
