# Helpers

Helpers are the primary UI abstraction — not partials or view components. They
output complete HTML with Tailwind classes and auto-attach Stimulus controllers.

## Visual layers

The UI has three depth layers:

- **Layer -1 — Sidebar.** Dark (`bg-zinc-900`), fixed, always-present chrome.
  Depth is expressed through color alone — shadow can't darken a near-black
  surface. The sidebar's darkness is its shadow.
- **Layer 0 — Page.** The gray background (`bg-zinc-50`). The neutral ground
  everything else sits on.
- **Layer 1 — Cards and header.** White surfaces with `shadow-sm`. Shadow does
  the depth work here because the luminance gap from layer 0 is small.

Everything ON layer 1 is flat — no nested shadows. This is the shadow nesting
rule below.

## Shadow nesting rule [CRITICAL]

Never stack shadows. Only top-level cards and page header buttons get shadows.
Everything inside a card must be flat:

- `card_classes(shadow: false)` — nested card (border + bg, no shadow)
- `panel_classes` — border-only containment (tables, forms)
- `inset_classes` — grey bg + left accent stripe (metadata, definition lists)
- `button(..., shadow: false)` — button inside a card
- `f.submit` — shadow-free by default (forms are always inside cards)
- Form inputs, checkboxes, comboboxes — shadow-free by default
- Pagination controls — shadow-free (always inside panels)

**Keep shadows on:** page header buttons, standalone page-level action buttons
(e.g. "Retry All Failed" between sections), and top-level cards.

See `/kitchen_sink/cards` and `/kitchen_sink/buttons` for examples.
