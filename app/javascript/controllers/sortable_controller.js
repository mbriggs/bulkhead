import { Controller } from "@hotwired/stimulus"
import { getCsrfToken } from "lib/csrf"

// dragula is loaded as a UMD bundle via importmap and available globally
/* global dragula */

const query = {
  handle: "[data-sortable-target='handle']",
  item: "[data-sortable-target='item']",
  itemIdValueAttribute: "data-sortable-item-id-value" // More robust way to get ID attribute name
}

/**
 * @class SortableController
 * @extends Controller
 *
 * @description
 * Enables drag-and-drop sorting for a list of elements using Dragula.
 * Updates position data upon dropping an item and optionally persists
 * the new order to a backend endpoint.
 *
 * @property {HTMLElement[]} itemTargets - The elements that can be sorted.
 * @property {HTMLElement[]} handleTargets - The elements within items that initiate dragging.
 * @property {StringValue} endpointValue - Optional. The URL to send the updated positions to.
 * @property {StringValue} methodValue - Optional. The HTTP method for persistence request. Defaults to "PATCH".
 *
 * @fires sortable:sorted - Dispatched after successful sort. Detail: `{ fromIndex, toIndex, item }`
 * @fires sortable:error - Dispatched on persistence failure. Detail: `{ error, item }`
 *
 * @example Basic Usage
 * <div data-controller="sortable" data-sortable-endpoint-value="/items/reorder">
 *   <div data-sortable-target="item" data-sortable-item-id-value="1" data-position="0">
 *     <span data-sortable-target="handle">&#9776;</span> Item 1
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["item", "handle"]
  static values = {
    endpoint: { type: String, default: "" },
    method: { type: String, default: "PATCH" },
  }

  connect() {
    this.isRequestInProgress = false
    this.draggedElement = null // Store the element being dragged
    this.originalIndex = null  // Store its initial index

    // Add a class to the main container for potential styling
    this.element.classList.add("Sortable-container")

    // Add Sortable-handle class to all handle elements to show the three dots
    this.handleTargets.forEach(handle => {
      if (handle) {
        handle.classList.add("Sortable-handle")
      }
    })

    // Initialize positions if not already set
    this.initializePositions()
    this.initializeDragula()
  }

  disconnect() {
    if (this.drake) {
      this.drake.destroy()
      this.drake = null
    }
    this.element.classList.remove("Sortable-container")

    // Remove Sortable-handle class from all handle elements
    this.handleTargets.forEach(handle => {
      if (handle) {
        handle.classList.remove("Sortable-handle")
      }
    })

    // Ensure state is reset on disconnect
    this.isRequestInProgress = false
    this.draggedElement = null
    this.originalIndex = null
    this.cleanupVisualDragState() // Clean up any lingering styles
  }

  initializeDragula() {
    // Create a container array for Dragula
    const containers = [this.element];

    // Configure Dragula with proper handle selector
    this.drake = dragula(containers, {
      // Use the handle option directly instead of moves function
      handle: query.handle,
      direction: 'vertical',
      mirrorContainer: document.body
    });

    // Add error handling for drag events
    this.drake.on('drag', (el, source) => {
      try {
        this.handleDragStart(el);
      } catch (error) {
        console.error("[SortableController] Error in handleDragStart:", error);
        this.drake.cancel(true);
      }
    });

    this.drake.on('drop', (el, target, source, sibling) => {
      try {
        this.handleDrop(el, target, source, sibling);
      } catch (error) {
        console.error("[SortableController] Error in handleDrop:", error);
        this.cleanupVisualDragState();
      }
    });

    this.drake.on('cancel', (el, container, source) => {
      try {
        this.handleCancel(el, container, source);
      } catch (error) {
        console.error("[SortableController] Error in handleCancel:", error);
        this.cleanupVisualDragState();
      }
    });

    this.drake.on('over', (el, container, source) => {
      try {
        this.handleOver(el, container, source);
      } catch (error) {
        console.error("[SortableController] Error in handleOver:", error);
      }
    });

    this.drake.on('out', (el, container, source) => {
      try {
        this.handleOut(el, container, source);
      } catch (error) {
        console.error("[SortableController] Error in handleOut:", error);
      }
    });

    // HACK: Remove modal wrappers from the mirror clone to prevent duplicate IDs
    // and Stimulus controller errors. The real issue is modals rendered inside
    // sortable items, but moving them outside would require restructuring views.
    // This is the least invasive fix.
    this.drake.on('cloned', (clone, _original, type) => {
      if (type === 'mirror') {
        clone.querySelectorAll('[data-controller~="modal"]').forEach(el => el.remove());
      }
    });
  }

  handleDragStart(el) {
    if (this.isRequestInProgress) {
      this.drake.cancel(true) // Revert the drag immediately
      return
    }

    const startIndex = this.getItemPosition(el)
    if (startIndex === -1) {
      console.error("[SortableController] Drag start failed: Could not find position for item.", el)
      this.drake.cancel(true)
      return
    }

    this.draggedElement = el
    this.originalIndex = startIndex

    // Add a class to the body to indicate dragging state if needed
    document.body.classList.add('Sortable-bodyDragging')
  }

  handleOver(el, container, source) {
    // Add hover effect to potential drop targets (excluding the element being dragged)
    if (el !== this.draggedElement) {
      el.classList.add("Sortable-dragOver")
    }
  }

  handleOut(el, container, source) {
    // Remove hover effect
    el.classList.remove("Sortable-dragOver")
  }

  handleDrop(el, target, source, sibling) {
    // el: The element that was dropped
    // target: The container it was dropped into (should be this.element)
    // source: The container it came from (should be this.element)
    // sibling: The item element it was dropped next to (null if last)

    // If drag was cancelled before drop logic (e.g., during dragStart check)
    if (!this.draggedElement) {
      console.warn("[SortableController] Drop ignored: No dragged element tracked.")
      this.cleanupVisualDragState() // Ensure styles are reset
      return
    }

    // The dropped element `el` should be the same as `this.draggedElement`
    if (el !== this.draggedElement) {
      console.warn("[SortableController] Drop mismatch: Event element differs from tracked dragged element.");
      this.removeProcessingStyle(el)
      el.classList.remove("Sortable-dragOver")
      this.resetDragState()
      this.cleanupVisualDragState()
      return;
    }

    // Update positions *before* reading the new position
    this.updatePositions()

    // Now read the *new* position of the dropped element
    const newPosition = this.getItemPosition(el)
    if (newPosition === -1) {
      console.error("[SortableController] Drop failed: Could not find position after drop.", el)
      this.handleRequestFailure(el, new Error("Position missing after drop"))
      return
    }

    const fromIndex = this.originalIndex
    const toIndex = newPosition
    const itemId = this.getItemId(el) || 'N/A'

    // If the position hasn't actually changed, no need to persist
    if (fromIndex === toIndex) {
      this.finalizeDrop(el, fromIndex, toIndex)
      return
    }

    // Attempt to persist if endpoint is configured
    if (this.hasEndpointValue && this.endpointValue) {
      this.setProcessingStyle(el)
      this.isRequestInProgress = true // Lock further drags
      this.persistPositions(el, fromIndex, toIndex)
    } else {
      // No endpoint, finalize the drop immediately
      this.finalizeDrop(el, fromIndex, toIndex)
    }
  }

  handleCancel(el, container, _source) {
    // Ensure the element that was being dragged has styles reset
    if (el) {
      this.removeProcessingStyle(el);
      el.classList.remove("Sortable-dragOver");
    }
    // Reset the core drag state and visual styles
    this.resetDragState()
    this.cleanupVisualDragState()
  }

  finalizeDrop(droppedElement, fromIndex, toIndex) {
    if (!droppedElement || !document.body.contains(droppedElement)) {
      console.warn("[SortableController] Dropped item element no longer exists, skipping finalization effects.")
    } else {
      // Apply flash effect
      droppedElement.classList.add("Sortable-flash")
      setTimeout(() => {
        if (droppedElement && document.body.contains(droppedElement)) {
          droppedElement.classList.remove("Sortable-flash")
        }
      }, 1000) // Duration matches CSS

      // Ensure processing style is removed if persistence was skipped/successful
      this.removeProcessingStyle(droppedElement)
    }

    // Reset core drag state and clean up visuals
    this.resetDragState()
    this.cleanupVisualDragState()

    // Dispatch event
    this.dispatch("sorted", { detail: { fromIndex, toIndex, item: droppedElement } })
  }

  persistPositions(droppedElement, fromIndex, toIndex) {
    const positionsPayload = this.itemTargets
      .map(itemEl => {
        const id = this.getItemId(itemEl)
        const position = this.getItemPosition(itemEl)
        const idNum = parseInt(id, 10)
        return { el: itemEl, id: id || 'N/A', idNum, position }
      })
      .filter(({ el, id, idNum, position }) => {
        if (id === 'N/A') {
          console.warn("[SortableController] Skipping item: Missing ID attribute.", el)
          return false;
        }
        if (isNaN(idNum)) {
          console.warn(`[SortableController] Skipping item: Invalid non-numeric ID '${id}'.`, el)
          return false;
        }
        if (position === -1) {
          console.warn(`[SortableController] Skipping item ID ${id}: Missing position.`, el)
          return false;
        }
        if (idNum <= 0) {
          return false;
        }
        return true;
      })
      .map(({ idNum, position }) => ({ id: idNum, position }));

    if (positionsPayload.length === 0) {
      console.error("[SortableController] No valid positions found to persist.")
      this.handleRequestFailure(droppedElement, new Error("No valid data to send"))
      return
    }

    const csrfToken = getCsrfToken()

    fetch(this.endpointValue, {
      method: this.methodValue.toUpperCase(),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(csrfToken && { 'X-CSRF-Token': csrfToken })
      },
      body: JSON.stringify({ positions: positionsPayload })
    })
      .then(response => {
        if (response.ok) {
          this.finalizeDrop(droppedElement, fromIndex, toIndex)
        } else {
          console.error(`[SortableController] Failed to save positions: HTTP status ${response.status}`)
          this.handleRequestFailure(droppedElement, new Error(`HTTP status ${response.status}`))
        }
      })
      .catch(error => {
        console.error("[SortableController] Error persisting positions:", error);
        this.handleRequestFailure(droppedElement, error);
      })
  }

  handleRequestFailure(failedElement, error = null) {
    console.error("[SortableController] Request to save positions failed.", {
      error: error instanceof Error ? error.message : String(error),
      item: failedElement || 'N/A'
    })

    // Attempt to apply visual error feedback
    if (failedElement && document.body.contains(failedElement)) {
      this.removeProcessingStyle(failedElement)
      failedElement.classList.add("Sortable-error");
      setTimeout(() => {
        if (failedElement && document.body.contains(failedElement)) {
          failedElement.classList.remove("Sortable-error")
        }
      }, 1500);
    }

    // Reset core drag state and visual styles
    this.resetDragState()
    this.cleanupVisualDragState()

    // Dispatch error event *before* potential reload
    this.dispatch("error", { detail: { error, item: failedElement } })

    // Reload to show flash message from server.
    Turbo.visit(location.href)
  }

  resetDragState() {
    this.isRequestInProgress = false
    this.draggedElement = null
    this.originalIndex = null
  }

  cleanupVisualDragState() {
    // Clean up styles applied during drag/hover from all items
    this.itemTargets.forEach(itemEl => {
      if (itemEl) {
        itemEl.classList.remove("Sortable-dragOver");
        this.removeProcessingStyle(itemEl);
      }
    });
    // Clean up body class
    document.body.classList.remove('Sortable-bodyDragging');
  }

  updatePositions() {
    this.itemTargets.forEach((itemElement, index) => {
      const currentPosition = this.getItemPosition(itemElement)
      if (currentPosition !== index) {
        this.setItemPosition(itemElement, index)

        // Also update any hidden form field with data-sortable-target="position"
        const positionField = itemElement.querySelector('[data-sortable-target="position"]')
        if (positionField && positionField.type === 'hidden') {
          positionField.value = (index + 1).toString() // 1-based indexing for database
        }
      }
    })
  }

  // Initialize positions for all items if not already set
  initializePositions() {
    this.itemTargets.forEach((itemElement, index) => {
      if (this.getItemPosition(itemElement) === -1) {
        this.setItemPosition(itemElement, index)
      }
    })
  }

  // Get position from dataset
  getItemPosition(itemElement) {
    if (!itemElement) return -1
    const position = itemElement.dataset.position
    return position !== undefined ? parseInt(position, 10) : -1
  }

  // Set position in dataset
  setItemPosition(itemElement, position) {
    if (!itemElement) return
    itemElement.dataset.position = position.toString()
  }

  getItemId(itemElement) {
    if (!itemElement) return null
    return itemElement.dataset.sortableItemIdValue
  }

  setProcessingStyle(element) {
    if (element) element.classList.add("Sortable-processing")
  }

  removeProcessingStyle(element) {
    if (element) element.classList.remove("Sortable-processing")
  }

}
