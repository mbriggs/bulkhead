import { Controller } from "@hotwired/stimulus";

// Enables submit button when input matches expected value.
// Used for high-impact delete confirmations.
export default class extends Controller {
  static targets = ["input", "submit"];
  static values = {
    expected: String,
  };

  validate() {
    const matches =
      this.inputTarget.value.toLowerCase() === this.expectedValue.toLowerCase();
    this.submitTarget.disabled = !matches;
  }
}
