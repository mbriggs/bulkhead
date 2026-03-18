// menu_controller.js
import { Controller } from "@hotwired/stimulus";
import { show, hide } from "controllers/visibility_toggle_controller";

/**
 * MenuController coordinates the behavior of a mobile menu.
 *
 * Values:
 * - state: The current state of the menu ("open" or "closed", default: "closed")
 *
 * Targets:
 * - toggleable: Elements to be toggled (must have VisibilityToggleController applied)
 *
 * Actions:
 * - open: Opens the menu
 * - close: Closes the menu
 *
 * Usage:
 * <div data-controller="menu">
 *   <button data-action="menu#toggle">Toggle Menu</button>
 *
 *   <div data-menu-target="toggleable"
 *        data-controller="visibility-toggle"
 *        data-visibility-toggle-visible-class="translate-x-0"
 *        data-visibility-toggle-hidden-class="-translate-x-full"
 *        class="fixed inset-y-0 left-0 transform">
 *     <!-- Menu content -->
 *   </div>
 *
 *   <div data-menu-target="toggleable"
 *        data-controller="visibility-toggle"
 *        data-visibility-toggle-visible-class="opacity-50"
 *        data-visibility-toggle-hidden-class="opacity-0 pointer-events-none"
 *        class="fixed inset-0 bg-black transition-opacity">
 *     <!-- Overlay -->
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["toggleable"];
  static values = {
    state: { type: String, default: "closed" },
  };

  connect() {
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleOutsideClick);
  }

  toggle(event) {
    if (this.stateValue === "open") {
      this.close(event);
    } else {
      this.open(event);
    }
  }

  open(event) {
    this.stateValue = "open";
  }

  close(event) {
    this.stateValue = "closed";
  }

  handleOutsideClick(event) {
    // Close if clicking outside this menu element
    if (!this.element.contains(event.target)) {
      this.close();
    }
  }

  stateValueChanged() {
    if (this.stateValue === "open") {
      document.addEventListener("click", this.boundHandleOutsideClick);
    } else {
      document.removeEventListener("click", this.boundHandleOutsideClick);
    }
    this.updateToggleables();
  }

  updateToggleables() {
    const toggleState = this.stateValue === "open" ? show : hide;
    this.toggleableTargets.forEach((target) => {
      toggleState(target);
    });
  }
}
