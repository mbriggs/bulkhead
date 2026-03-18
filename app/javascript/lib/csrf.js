// Centralized CSRF token handling
// All fetch requests to Rails need the CSRF token from the meta tag

export function getCsrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

export function csrfHeaders() {
  const token = getCsrfToken()
  return token ? { "X-CSRF-Token": token } : {}
}
