import { Controller } from "@hotwired/stimulus";

/**
 * VisibilityToggleController handles showing/hiding an element with transition effects.
 *
 * By default the controller transitions its own root element. When a `content`
 * target is present, transitions apply to the target instead — this lets a
 * toggle button live inside the controller scope without being hidden.
 *
 * Targets:
 * - content (optional): Element to show/hide. Falls back to the root element.
 *
 * Values:
 * - state ("visible"|"hidden", default "hidden"): Current visibility state.
 *
 * Attributes:
 * - data-visibility-toggle-visible-class: Classes when visible (default "visibility-visible")
 * - data-visibility-toggle-hidden-class: Classes when hidden (default "visibility-transparent")
 * - data-visibility-toggle-showing-class: Transition classes for showing
 * - data-visibility-toggle-hiding-class: Transition classes for hiding
 * - data-visibility-toggle-hiding-complete-class: Applied after hide transition ends (e.g. "hidden")
 *
 * Actions:
 * - toggle: Flips state between visible and hidden
 *
 * Exported functions:
 * - show(element) / hide(element): Set state from companion controllers
 *
 * Usage (root element):
 * <div data-controller="visibility-toggle"
 *      data-visibility-toggle-state-value="hidden"
 *      class="visibility-panel">
 *   Content that toggles
 * </div>
 *
 * Usage (content target with inline trigger):
 * <div data-controller="visibility-toggle"
 *      data-visibility-toggle-state-value="visible"
 *      data-visibility-toggle-visible-class="visibility-visible"
 *      data-visibility-toggle-hidden-class="visibility-lifted"
 *      data-visibility-toggle-hiding-complete-class="hidden">
 *   <button data-action="click->visibility-toggle#toggle">Toggle</button>
 *   <div data-visibility-toggle-target="content" class="visibility-panel">
 *     Panel content
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["content"];
  static values = {
    state: { type: String, default: "hidden" },
  };

  // The element that gets shown/hidden. Defaults to the controller root,
  // but delegates to a content target when one is present so the trigger
  // (e.g. a toggle button) can live inside the controller scope.
  get toggleElement() {
    return this.hasContentTarget ? this.contentTarget : this.element;
  }

  get isVisible() {
    return this.stateValue === "visible";
  }

  toggle() {
    this.stateValue = this.isVisible ? "hidden" : "visible";
  }

  connect() {
    this.visibleClasses = this.readClass("visibleClass", "visibility-visible");
    this.hiddenClasses = this.readClass("hiddenClass", "visibility-transparent");
    this.showingClasses = this.readClass(
      "showingClass",
      "visibility-transition",
    );
    this.hidingClasses = this.readClass(
      "hidingClass",
      "visibility-transition fast",
    );
    this.hidingCompleteClasses = this.readClass("hidingCompleteClass", null);

    if (!this.isVisible) {
      this.toggleElement.classList.add(...this.hidingCompleteClasses);
    }

    this.applyClasses(this.isVisible);

    this.connected = true;
  }

  disconnect() {
    this.connected = false;
  }

  // this is necessary because there is no default stimulus class values
  readClass(attributeName, defaultClasses) {
    const classes = this.data.get(attributeName);
    if (classes) {
      return classes.split(" ");
    }

    if (!defaultClasses) {
      return [];
    }

    return defaultClasses.split(" ");
  }

  stateValueChanged() {
    // ignore initial transition before class is wired up
    if (!this.connected) {
      return;
    }

    const el = this.toggleElement;
    let isVisible = this.isVisible;

    let transitionClasses = isVisible
      ? this.showingClasses
      : this.hidingClasses;

    // set classes required for transition
    el.classList.add(...transitionClasses);
    el.classList.remove(...this.hidingCompleteClasses);

    // when transition completes, clean up classes
    const onTransitionEnd = (e) => {
      if (e.target === el) {
        el.removeEventListener("transitionend", onTransitionEnd);
        el.classList.remove(...transitionClasses);

        if (!isVisible) {
          el.classList.add(...this.hidingCompleteClasses);
        }
      }
    };

    el.addEventListener("transitionend", onTransitionEnd);

    // force reflow so the browser acknowledges current state before transitioning
    el.offsetHeight; // eslint-disable-line no-unused-expressions

    // apply classes
    this.applyClasses(isVisible);
  }

  applyClasses(isVisible) {
    const el = this.toggleElement;
    if (isVisible) {
      el.classList.remove(...this.hiddenClasses);
      el.classList.add(...this.visibleClasses);
    } else {
      el.classList.remove(...this.visibleClasses);
      el.classList.add(...this.hiddenClasses);
    }
  }
}

export function show(element) {
  element.setAttribute("data-visibility-toggle-state-value", "visible");
}

export function hide(element) {
  element.setAttribute("data-visibility-toggle-state-value", "hidden");
}
