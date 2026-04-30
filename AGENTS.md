# AGENTS.md

## Styling Standard

Bulkhead is intended to be embedded into host applications as a git subtree. Its markup should read like a local starter UI, not like an external framework.

- Use plain component classes for roots and parts: `button`, `card`, `card-header`, `alert-icon`, `table-cell`.
- Use plain modifier classes in markup: `primary`, `secondary`, `danger`, `success`, `sm`, `lg`, `active`, `disabled`.
- Do not use namespaced or BEM-style class names such as `bh-button`, `button__icon`, or `button--primary`.
- Do not style naked modifier selectors by themselves. Scope modifier styles to the component that owns them:

```css
.button.primary {
  /* primary button styles */
}

.alert.danger {
  /* danger alert styles */
}
```

- Only write global selectors like `.primary` or `.sm` when the class is intentionally a true global utility.
- Prefer readable HTML such as `<button class="button primary sm">Save</button>` over opaque or framework-like class names.
- Do not reintroduce Tailwind-style compatibility shims. If markup needs behavior or layout, add an authored class that names the component, state, or demo pattern being styled.
