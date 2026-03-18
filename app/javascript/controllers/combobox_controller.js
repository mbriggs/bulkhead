import { Controller } from "@hotwired/stimulus"
import { debounce } from "lib/debounce"

// Searchable combobox — a text input with a filterable dropdown list.
// Backs the selected value into a hidden input for form submission.
//
// Supports two modes:
// - Local: filters static <li> options rendered in the HTML
// - Remote: fetches options from a URL as the user types
//   Endpoint contract: GET url?q=term → JSON [{ label, value }, …]
//
// Values:
// - url:        endpoint for remote mode (omit for local filtering)
// - blankLabel: label for the "no selection" option (e.g. "All authors")
export default class extends Controller {
  static targets = ["input", "hidden", "listbox", "option"]
  static values = { url: String, blankLabel: String }

  connect() {
    this.filter = debounce(this._filter.bind(this), 80)
    this.activeIndex = -1
    this._boundOutsideClick = this._handleOutsideClick.bind(this)
    this._confirmedLabel = this.inputTarget.value
    this._confirmedValue = this.hiddenTarget.value
    this._lastFetchedQuery = null

    // Clicking an option fires mousedown → blur → click. Preventing default on
    // mousedown keeps focus on the input so blur doesn't close the listbox
    // before click reaches the option.
    this._boundPreventBlur = (e) => e.preventDefault()
    this.listboxTarget.addEventListener("mousedown", this._boundPreventBlur)
  }

  disconnect() {
    document.removeEventListener("click", this._boundOutsideClick)
    this.listboxTarget.removeEventListener("mousedown", this._boundPreventBlur)
    this.filter.cancel()
    if (this._abortController) this._abortController.abort()
  }

  // -- Actions ----------------------------------------------------------------

  // Opens the dropdown and populates it. Used by focus action.
  open() {
    if (this._isOpen()) return
    this._openListbox()

    if (this.hasUrlValue) {
      this._fetchRemote(this.inputTarget.value.trim())
    } else {
      this._showAllOptions()
    }
  }

  close({ revert = false } = {}) {
    if (!this._isOpen()) return

    if (revert) {
      this.inputTarget.value = this._confirmedLabel
      this.hiddenTarget.value = this._confirmedValue
    } else {
      this._commitOrRevert()
    }

    this.listboxTarget.classList.add("hidden")
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.activeIndex = -1
    this._lastFetchedQuery = null
    this._clearHighlight()
    document.removeEventListener("click", this._boundOutsideClick)
  }

  // Opens the listbox (if needed) then filters — avoids the double-fetch that
  // would happen if we called open() (which populates) then filter().
  onInput(event) {
    const autocomplete = event.inputType?.startsWith("insert") ?? false
    if (!this._isOpen()) this._openListbox()

    if (this.hasUrlValue) {
      this.filter({ autocomplete })
    } else {
      // Local filtering is just CSS class toggles — run synchronously so
      // typeahead fills in the same frame as the keystroke (no flicker).
      this.filter.cancel()
      this._filter({ autocomplete })
    }
  }

  // Closes the dropdown on blur (e.g. Tab away). Commit-or-revert logic inside
  // close() decides whether the typed value sticks.
  onBlur() {
    this.close()
  }

  select(event) {
    this._selectOption(event.currentTarget)
  }

  keydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.open()
        this._moveHighlight(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this._moveHighlight(-1)
        break
      case "ArrowRight":
        // Accept typeahead completion: collapse selection to end
        if (this.inputTarget.selectionStart !== this.inputTarget.selectionEnd) {
          event.preventDefault()
          this.inputTarget.selectionStart = this.inputTarget.value.length
        }
        break
      case "Enter":
        if (this._isOpen()) {
          if (this.activeIndex >= 0) {
            event.preventDefault()
            const visible = this._visibleOptions()
            if (visible[this.activeIndex]) this._selectOption(visible[this.activeIndex])
          } else {
            // Commit typeahead match even without a highlighted option
            const match = this._findExactMatch(this.inputTarget.value)
            if (match) {
              event.preventDefault()
              this._selectOption(match)
            }
          }
        }
        break
      case "Escape":
        this.close({ revert: true })
        break
    }
  }

  // -- Private ----------------------------------------------------------------

  _isOpen() {
    return !this.listboxTarget.classList.contains("hidden")
  }

  _openListbox() {
    this.listboxTarget.classList.remove("hidden")
    this.inputTarget.setAttribute("aria-expanded", "true")
    this.activeIndex = -1
    this._clearHighlight()
    document.addEventListener("click", this._boundOutsideClick)
  }

  _filter({ autocomplete = false } = {}) {
    const query = this.inputTarget.value.trim()
    this.hiddenTarget.value = ""

    // Always narrow existing options locally first — gives instant feedback.
    // Remote mode then fetches authoritative results; when the response lands,
    // _replaceOptions swaps the DOM and _autocomplete's idempotency check
    // prevents a redundant input update if the best match hasn't changed.
    this._filterLocal(query.toLowerCase())
    if (autocomplete) this._autocomplete()

    if (this.hasUrlValue) this._fetchRemote(query, { autocomplete })

    this.activeIndex = -1
    this._clearHighlight()
  }

  _filterLocal(query) {
    if (query === "") {
      this._showAllOptions()
    } else {
      this.optionTargets.forEach(option => {
        const text = option.textContent.toLowerCase()
        option.classList.toggle("hidden", !text.includes(query))
      })
    }
  }

  // Fills the input with the best prefix match and selects the suffix so the
  // next keystroke replaces it. Only called on insertion input events.
  // Uses selectionStart to find the typed prefix — when autocomplete previously
  // ran, the selection marks the boundary between typed and auto-filled text.
  // Skips re-application when the completion hasn't changed (avoids flicker on
  // remote fetches that return the same best match).
  _autocomplete() {
    const typed = this.inputTarget.value.substring(0, this.inputTarget.selectionStart)
    if (typed === "") return

    const match = this._visibleOptions().find(option => {
      if (option.dataset.value === "") return false
      return option.textContent.trim().toLowerCase().startsWith(typed.toLowerCase())
    })

    if (match) {
      const fullText = match.textContent.trim()
      if (this.inputTarget.value === fullText) return
      this.inputTarget.value = fullText
      this.inputTarget.setSelectionRange(typed.length, fullText.length)
    }
  }

  // Commits the typed value if it changed and exactly matches a visible
  // option. Otherwise reverts to the previously confirmed values.
  _commitOrRevert() {
    if (this.inputTarget.value !== this._confirmedLabel) {
      const match = this._findExactMatch(this.inputTarget.value)
      if (match) {
        const value = match.dataset.value
        const label = value === "" ? "" : match.textContent.trim()
        this.hiddenTarget.value = value
        this.inputTarget.value = label
        this._confirmedLabel = label
        this._confirmedValue = value
        return
      }
    }

    this.inputTarget.value = this._confirmedLabel
    this.hiddenTarget.value = this._confirmedValue
  }

  // Finds a visible option whose text exactly matches the input (case-insensitive).
  _findExactMatch(text) {
    const normalized = text.trim().toLowerCase()
    if (normalized === "") return null
    return this._visibleOptions().find(option =>
      option.textContent.trim().toLowerCase() === normalized
    )
  }

  async _fetchRemote(query, { autocomplete = false } = {}) {
    // The current options already cover any refinement of the last fetched
    // query — local filtering is enough, no need to round-trip.
    if (this._lastFetchedQuery !== null && query.startsWith(this._lastFetchedQuery)) return

    if (this._abortController) this._abortController.abort()
    this._abortController = new AbortController()

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    try {
      const response = await fetch(url, {
        headers: { "Accept": "application/json" },
        signal: this._abortController.signal
      })
      if (!response.ok) return
      const results = await response.json()
      this._lastFetchedQuery = query
      this._replaceOptions(results)
      if (autocomplete) this._autocomplete()
    } catch (error) {
      if (error.name !== "AbortError") throw error
    }
  }

  _replaceOptions(results) {
    const options = []

    if (this.hasBlankLabelValue) {
      options.push(this._buildOptionElement(this.blankLabelValue, "", true))
    }

    results.forEach(({ label, value }) => {
      options.push(this._buildOptionElement(label, value, false))
    })

    this.listboxTarget.replaceChildren(...options)
  }

  _buildOptionElement(label, value, blank) {
    const li = document.createElement("li")
    li.setAttribute("role", "option")
    li.dataset.comboboxTarget = "option"
    li.dataset.action = "click->combobox#select"
    li.dataset.value = value
    li.textContent = label
    const textColor = blank
      ? "text-zinc-500 dark:text-zinc-400"
      : "text-zinc-900 dark:text-zinc-100"
    li.className = `cursor-pointer select-none px-3 py-2 ${textColor} hover:bg-primary-600 hover:text-white dark:hover:bg-primary-500`
    return li
  }

  _showAllOptions() {
    this.optionTargets.forEach(option => option.classList.remove("hidden"))
  }

  _visibleOptions() {
    return this.optionTargets.filter(o => !o.classList.contains("hidden"))
  }

  _moveHighlight(direction) {
    const visible = this._visibleOptions()
    if (visible.length === 0) return

    this._clearHighlight()

    this.activeIndex += direction
    if (this.activeIndex < 0) this.activeIndex = visible.length - 1
    if (this.activeIndex >= visible.length) this.activeIndex = 0

    const option = visible[this.activeIndex]
    option.classList.add("bg-primary-600", "text-white", "dark:bg-primary-500")
    option.id = `${this.inputTarget.id}-active`
    this.inputTarget.setAttribute("aria-activedescendant", option.id)
    option.scrollIntoView({ block: "nearest" })
  }

  _clearHighlight() {
    this.optionTargets.forEach(option => {
      option.classList.remove("bg-primary-600", "text-white", "dark:bg-primary-500")
      option.removeAttribute("id")
    })
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  _selectOption(option) {
    const value = option.dataset.value
    // Blank option clears display so the placeholder shows through
    const label = value === "" ? "" : option.textContent.trim()
    const changed = this.hiddenTarget.value !== value
    this.hiddenTarget.value = value
    this.inputTarget.value = label
    this._confirmedLabel = label
    this._confirmedValue = value
    this.close()
    if (changed) this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
