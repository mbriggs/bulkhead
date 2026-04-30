# Bulkhead: Design flare + accessibility hardening

## Goal

Two outcomes from one pass through the CSS layer:

1. **Less austere.** Add three recurring "signature" moves so Bulkhead reads as designed, not templated — without abandoning the system's restraint.
2. **AA-clean and resilient.** Close the accessibility gaps surfaced in the design review (focus discipline, motion, forced-colors, contrast) and finish the housekeeping (type tier, spacing tokens, semantic surfaces).

These two threads share files and cascade order, so they ship together.

## Background and reasoning

Bulkhead is a non-isolated Rails engine providing helpers + static CSS + Stimulus controllers. It uses `@layer theme, base, components` with one file per component family. Tokens live in `tokens.css` (Tailwind v4 OKLCH palette + a semantic remap to `primary/danger/success/warning/info`). Dark mode is class-driven (`html.is-dark`) with overrides in `dark.css`.

A designer-hat audit landed a prioritized list. The user picked the first seven items plus three flare additions to ship as one batch. Before drafting, we considered:

- **Why bundle flare with a11y?** They touch the same files (`tokens.css`, `buttons.css`, `forms.css`, `surfaces.css`, `dark.css`) and the same cascade. Doing them in one pass means one round of kitchen-sink visual review instead of two, and the semantic-surface refactor (#7) is the natural place to introduce tinted shadows (flare) since both are surface-level concerns.
- **Why these three flare moves and not others?** We considered subtle gradients on `.primary`, sliding tab indicators, warmer dark surfaces, a display font for h1s, and animated micro-interactions. We rejected the broader set because flare ages faster than restraint — the strongest design signature is one or two recurring moves, not seven decorative touches. Chromatic shadows + signature focus ring + custom empty-state illustrations are the picks because each *recurs* across the system (every card, every focusable element, every empty list) rather than appearing once and feeling themed.
- **Why not also build the ramps (typographic, dark-warmth, sliding indicators)?** They're real wins but they're additive; they don't unblock anything else and they're easy to ship in a follow-up. Keep this plan focused.

## Scope

### Flare (3 moves)

**F1. Chromatic shadows.**
Cards, popovers (modal, page-menu, combobox-listbox, tooltip), and standalone primary buttons currently use `rgb(0 0 0 / 0.05–0.1)`. Replace with primary-tinted shadows: e.g. `0 1px 3px color-mix(in oklab, var(--color-primary-500) 12%, transparent)`. The tint should be subtle enough that surfaces don't read as "blue cards" — the goal is "lifted with intent," not themed. Maintain neutral `0 0 0 / 0.05` ring outlines (the 1px hairline shadow that defines edge); only the *drop* component of the shadow gets tinted.

In dark mode, switch the tint base to a slightly desaturated primary (or use `color-mix` against `--color-primary-400`) so the shadow doesn't disappear against zinc-800.

**F2. Signature focus ring.**
Replace ad-hoc `outline: 2px solid var(--color-primary-500); outline-offset: 2px` with a shared two-tone ring used on every focusable element: white inner halo (1–2px) + primary-500 outer (2px), via box-shadow stacking or `outline` + `box-shadow`. This recurs everywhere keyboard users land, so it's a real design signature. Define it once as a custom property (e.g., `--focus-ring`) so components reference it rather than redefining.

This move overlaps with a11y fix #2 (standardize `:focus-visible`) — they ship as one pass.

**F3. Custom empty-state illustrations.**
The `empty_state` helper currently passes a heroicon (`:inbox` default, others overridable) into a 3rem icon slot. Replace the icon slot with a small (96–128px) custom line illustration. Two ways to do this:

- **(Preferred)** Ship a small set of inline SVG illustrations under `app/assets/images/bulkhead/empty/` and wire them to a named-prop API (`empty_state(..., illustration: :no_results)`). Five-to-seven illustrations covers ~90% of admin cases: `no_results`, `empty_inbox`, `no_data`, `error`, `success`, `permission`, `loading`. Keep the existing `icon:` parameter as a fallback.
- Style: thin (1.5–2px) stroke, two-color (zinc-300 base + primary-300 accent), no fills. Matches the system's existing line-icon vocabulary. In dark mode, swap zinc-300 → zinc-600, primary-300 → primary-400.

Illustration sourcing: hand-author or adapt openly-licensed sets (unDraw, Storyset on permissive license). Implementer's call — don't gate the rest of the plan on illustration finalization. If illustrations slip, ship the API and a placeholder; iterate.

### Accessibility / housekeeping (fixes 1–7)

**#1. Reduced motion + forced-colors.**
- One global `@media (prefers-reduced-motion: reduce)` block that nukes the offenders: `.skeleton`, `.status-circle.active .status-circle-dot` pulse, `Sortable-flash`/`Sortable-error`, `.toggle-slider` translate, `.modal-panel` transitions, `.page-header-inner.scrolled` backdrop transitions, `.visibility-transition`, `.spinner-icon`/`.spinning`. Lives at the bottom of `utilities.css` (the natural cross-cutting home).
- One `@media (forced-colors: active)` block: input focus falls back to `outline: 2px solid Highlight` (since the inset box-shadow is invisible in High Contrast). Same block can shore up button focus and any other inset-shadow-only state.

**#2. `:focus-visible` discipline.**
Convert every `:focus` to `:focus-visible` except where a permanent visible state is intentional (none in the current code, on review). Add explicit focus-visible rings to `.button.secondary`, `.button.soft`, `.button.link` — they currently fall through to UA defaults. Use the `--focus-ring` custom property from F2.

**#3. Muted-grey contrast.**
Sweep content (not decorative) text using zinc-400 on white and bump to zinc-500. Confirmed offenders from review: `.stepper-label.pending`, `.stepper-time`, `.stage-bar-label` (default state). Decorative greys (icon-on-icon, dividers, fallback chevrons) stay at zinc-400. Implementer should re-grep `var(--color-zinc-400)` and judge case by case.

In dark mode, the parallel sweep is zinc-500 → zinc-400 for the same elements (already roughly the inverse, but worth verifying contrast in the dark stanza).

**#4. `--text-xl` + card-title tier.**
Add `--text-xl: 1.25rem` (line-height 1.75rem) to `tokens.css`. Introduce a *new* card-title size that uses `--text-xl` for cases where the existing 1.125rem feels under-weighted (e.g. detail-card titles inside page bodies). Don't blanket-replace existing 1.125rem usage — different headings live at different levels and the implementer should choose the one or two spots where the upgrade pays off (likely `.card-title`, leaving `.modal-title`/`.stepper-title` alone for now). The kitchen sink will tell you.

**#5. Tooltips on `:focus-within`.**
One-line fix in `utilities.css`: `.tooltip:hover .tooltip-bubble, .tooltip:focus-within .tooltip-bubble { opacity: 1 }`. Verify the `tooltip` helper applies `tabindex` correctly (or relies on the wrapped element being focusable) so this actually fires for keyboard users — if the helper wraps non-focusable elements, that's a separate fix.

**#6. Spacing scale.**
Two paths; pick one:
- **Adopt:** define `--space-1` through `--space-12` as multiples of `--spacing` (0.25rem). Sweep components and replace bespoke rem values with tokens. Higher cost, durable payoff.
- **Delete:** drop the orphan `--spacing` token. Lower cost, defers the discipline.

Default to **adopt** if the implementer is willing to budget the sweep; else delete and file a follow-up. Either way, leave the system internally consistent.

**#7. Semantic surface tokens.**
This is the biggest piece and the foundation everything else benefits from. Introduce a layer of semantic tokens in `tokens.css`:

```css
:root {
  --surface-1: var(--color-white);          /* card, modal-panel */
  --surface-2: var(--color-zinc-50);        /* page bg, table thead, hover */
  --surface-sunken: var(--color-zinc-100);  /* segmented bg, code-block */
  --text-1: var(--color-zinc-900);          /* primary content */
  --text-2: var(--color-zinc-700);          /* secondary content */
  --text-muted: var(--color-zinc-500);      /* hints, captions */
  --border-1: var(--color-zinc-200);        /* default borders */
  --border-strong: var(--color-zinc-300);   /* input rings */
  --shadow-card: 0 1px 3px color-mix(in oklab, var(--color-primary-500) 12%, transparent);
  --focus-ring: 0 0 0 2px var(--color-white), 0 0 0 4px var(--color-primary-500);
}
html.is-dark { /* same names, dark values */ }
```

Sweep component files to reference semantic tokens. Then **delete** the dark overrides that become redundant — `dark.css` should shrink substantially (target: roughly half its current size, ~250 lines). What remains in `dark.css` is the irreducible stuff (badge tints, alert-50-bg color shifts, syntect-style overrides in rich-text). The semantic-surface tokens also ground F1 (chromatic shadows) and F2 (focus ring) in named tokens.

Don't try to make this perfect on the first pass. The goal is a meaningful reduction in dark.css, not zero. Components that resist the abstraction (rich-text colors, the badge color matrix) are fine to leave on raw palette tokens.

## Sequence

The work has dependencies; this order minimizes rework:

1. **Tokens first.** Land `--text-xl`, semantic surface tokens, `--focus-ring`, `--shadow-card`, and (if adopting) the `--space-*` scale. Keep the old palette tokens — semantic tokens reference them.
2. **Sweep components to use semantic tokens.** Touch one family file at a time. `dark.css` deletions happen in the same commits so the diff tells the whole story. After this step, F1 (chromatic shadows on cards) is already shipped via `--shadow-card`.
3. **Focus ring (F2 + #2 + parts of #1).** Apply `--focus-ring` everywhere; convert `:focus` → `:focus-visible`; add the `forced-colors` fallback for inputs.
4. **Reduced motion (#1) + tooltip focus-within (#5).** Cross-cutting one-shot blocks in `utilities.css`.
5. **Contrast sweep (#3) + card-title tier (#4).** Visual judgment calls, easier to land once the surface refactor settles.
6. **Empty-state illustrations (F3).** Independent of the rest; can land first or last. The helper API change is small; the illustration set determines the timeline.

Each step should leave the kitchen sink intact. Run `bin/rails server` and walk every kitchen-sink page after each step in light *and* dark mode. The kitchen sink is the regression test for visual changes; treat it as such.

## Verification

- `test/css/tone_coverage_test.rb` already asserts every tone the helpers can emit has a CSS rule. Update or extend if new tones are introduced (illustration accent colors, surface tokens used by helpers).
- Run the engine test suite: `cd vendor/bulkhead && rake test`.
- Manual kitchen-sink walkthrough at `/kitchen_sink/*` in both light and dark modes. Pages to verify hardest: `cards`, `forms`, `tabs`, `interactive`, `tables`, `empty_states`, `typography`, `reader_mode`. Tab through every focusable element to confirm the new focus ring lands consistently.
- Browser accessibility checks: macOS VoiceOver tab nav, Chrome forced-colors emulation (DevTools → Rendering → Emulate CSS media feature `forced-colors: active`), reduced-motion emulation in the same panel.
- Contrast: spot-check a few changed greys with a contrast tool to confirm AA on the size used.

## Out of scope (deferred follow-ups)

Documented here so they aren't lost:

- **Type ramp on wide screens.** Body 14 → 15/16 at `>= 64rem`; page-header-title beyond 1.875rem.
- **Sliding tab/segmented indicators.** Animated, not just color-swapped.
- **Warmer dark surfaces.** A touch of indigo in the dark zinc grays.
- **Subtle gradient on `.primary` buttons.** Considered for flare, deferred — the chromatic shadow does similar work with less risk of dating poorly.
- **Combobox hover vs. aria-selected distinction.** Listed in the audit; small but real.
- **Token gaps (`warning-100`, `warning-600`, `info-100`).** Fill when something needs them.
- **Button hover/active polarity (lighten on hover).** Worth a deliberate review session, not a code change today.

## Skills / docs to load at implementation start

- `app/helpers/CLAUDE.md` — the depth-layer doctrine (Layer -1/0/1) and the shadow-nesting rule. Critical for the chromatic-shadow work; only top-level cards and page-header buttons get shadows, and the chromatic tint must respect that.
- `README.md` — CSS layer/import structure, Tones registry, kitchen-sink routes.
- `test/css/tone_coverage_test.rb` — to understand the drift-prevention contract before adding new color tokens.
- `app/assets/stylesheets/bulkhead.css` — the `@layer theme, base, components` declaration and import order. New tokens go in `tokens.css` (theme layer); everything else lands in components.
- The `frontend-design` skill is available and may help when authoring empty-state illustrations or evaluating the chromatic-shadow tint level — useful but not required.
