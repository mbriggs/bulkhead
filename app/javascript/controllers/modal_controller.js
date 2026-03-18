import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog", "content"];
  static values = {
    closeOnSubmit: Boolean,
  };

  connect() {
    // Ensure dialog has an ID
    if (!this.dialogTarget.id) {
      this.dialogTarget.id = `modal-${Math.random().toString(36).substring(2, 11)}`;
    }

    // Check for duplicate dialog IDs
    const dialogs = document.querySelectorAll(`dialog#${CSS.escape(this.dialogTarget.id)}`);
    if (dialogs.length > 1) {
      console.error(
        `[ModalController] Duplicate dialog ID: "${this.dialogTarget.id}". Found ${dialogs.length} dialogs.`
      );
    }

    // Inject modal ID into forms just before submission
    this.injectModalId = this.injectModalId.bind(this);
    this.dialogTarget.addEventListener("turbo:before-fetch-request", this.injectModalId);

    // Handle form responses
    if (this.closeOnSubmitValue) {
      this.handleResponse = this.handleResponse.bind(this);
      this.element.addEventListener("turbo:submit-end", this.handleResponse);
    }

    // Preserve dialog open/closed state across Turbo morph page refreshes.
    // The dialog has a stable id so Idiomorph morphs it in-place (same DOM
    // node, top layer preserved). But the server-rendered HTML doesn't include
    // the `open` attribute, so Idiomorph removes it — closing the dialog.
    // Preventing that attribute morph keeps the dialog open through refreshes.
    // See hotwired/turbo#1239
    this.preserveDialogState = this.preserveDialogState.bind(this);
    document.addEventListener("turbo:before-morph-attribute", this.preserveDialogState);
  }

  disconnect() {
    document.removeEventListener("turbo:before-morph-attribute", this.preserveDialogState);

    if (this.hasDialogTarget) {
      // Safety net: close the dialog before disconnect to clear the browser's
      // top layer in case morphing prevention didn't fire (e.g. full page
      // navigation or element removal outside of morphing).
      if (this.dialogTarget.open) {
        this.dialogTarget.close();
      }
      this.dialogTarget.removeEventListener("turbo:before-fetch-request", this.injectModalId);
    }

    if (this.closeOnSubmitValue) {
      this.element.removeEventListener("turbo:submit-end", this.handleResponse);
    }
  }

  injectModalId(event) {
    // Add modal ID to the fetch request body
    const form = event.target;
    if (form.tagName !== "FORM") return;

    // Inject hidden field if not present
    if (!form.querySelector('input[name="modal_submittable_id"]')) {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "modal_submittable_id";
      input.value = this.dialogTarget.id;
      form.appendChild(input);
    }
  }

  open(event) {
    event.preventDefault();
    this.previouslyFocusedElement = document.activeElement;
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus();
      this.previouslyFocusedElement = null;
    }
  }

  // Close modal and navigate - for links inside modals that need to trigger navigation
  closeAndNavigate(event) {
    const link = event.target.closest('a');
    if (link?.href) {
      event.preventDefault();
      this.dialogTarget.close();
      Turbo.visit(link.href, { action: link.dataset.turboAction || "advance" });
    } else {
      this.dialogTarget.close();
    }
  }

  preserveDialogState(event) {
    if (event.detail.attributeName === "open" && event.target === this.dialogTarget) {
      event.preventDefault();
    }
  }

  backdropClick(event) {
    // Only close if click started and ended on the backdrop (not dragged from inside)
    if (event.type === "mousedown") {
      const content = this.hasContentTarget ? this.contentTarget : this.dialogTarget.firstElementChild;
      this.clickStartedOnBackdrop = content && !content.contains(event.target);
    } else if (event.type === "click" && this.clickStartedOnBackdrop) {
      const content = this.hasContentTarget ? this.contentTarget : this.dialogTarget.firstElementChild;
      if (content && !content.contains(event.target)) {
        this.dialogTarget.close();
      }
      this.clickStartedOnBackdrop = false;
    }
  }

  handleResponse(event) {
    const response = event.detail?.fetchResponse;

    if (response?.succeeded) {
      this.dialogTarget.close();
    }
  }
}
