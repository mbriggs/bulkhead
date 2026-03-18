// Lodash-compatible debounce function
export function debounce(func, wait) {
  let timeoutId = null

  const debounced = function(...args) {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => func.apply(this, args), wait)
  }

  debounced.cancel = function() {
    clearTimeout(timeoutId)
    timeoutId = null
  }

  return debounced
}
