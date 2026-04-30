# Bulkhead

A reusable Rails engine providing the view layer — helpers, Stimulus
controllers, static CSS, and shared partials.

Distributed as a **git subtree**, not a published gem. You clone it into your
app, work on it locally, and push changes back upstream.

## What's inside

- **18 helpers** — buttons, forms, tables, modals, cards, pages, icons, badges,
  pagination, alerts, stage bars, steppers, admin layout, and more
- **26 Stimulus controllers** — modal, sortable, combobox, tabs, datepicker,
  clipboard, disclosure, truncate, and more
- **37 shared partials** — forms, modals, page chrome, UI components, admin
  shared, flash messages
- **Kitchen sink** — dev-only component showcase at `/kitchen_sink`
- **Static CSS design system** — semantic color system (primary, danger,
  success, warning, info) + rich-text variants
- **Vendor assets** — dragula (drag-and-drop), air-datepicker

## Requirements

- Rails 8.0+
- Propshaft + Importmaps (no Webpack/esbuild)
- Hotwire (Turbo + Stimulus)

## Installation

From your Rails app root:

```bash
# 1. Bootstrap — add the subtree into vendor/
git remote add bulkhead git@github.com:mbriggs/bulkhead.git
git fetch bulkhead
git subtree add --prefix vendor/bulkhead bulkhead master --squash

# 2. Create the bin symlink
ln -s ../vendor/bulkhead/bin/bulkhead bin/bulkhead

# 3. Run the install script (patches Gemfile and layout, bundles)
bin/bulkhead install
```

The install script:
- Adds `gem "bulkhead", path: "vendor/bulkhead"` to your Gemfile
- Adds `<%= stylesheet_link_tag "bulkhead", "data-turbo-track": "reload" %>`
  to your application layout
- Creates `bin/bulkhead` symlink if missing
- Runs `bundle install`

### How CSS integration works

Bulkhead ships `app/assets/stylesheets/bulkhead.css` as a regular Propshaft
asset. The engine registers its stylesheet path, so host apps include the CSS
directly from their layout:

```erb
<%= stylesheet_link_tag "bulkhead", "data-turbo-track": "reload" %>
```

No CSS build step or symlink is required.

`bulkhead.css` is a thin entry that `@import`s the layered files. Cascade
order is established up front; each file declares its own
`@layer X { ... }` block so the pieces can be edited independently:

- `bulkhead/tokens.css` — design tokens
- `bulkhead/base.css` — reset / element defaults
- `bulkhead/components/utilities.css` — small leaf primitives (tooltip, spacer, skeleton, avatar, code-block)
- `bulkhead/components/buttons.css` — button family
- `bulkhead/components/surfaces.css` — card, panel, inset, alert
- `bulkhead/components/forms.css` — form, field, input, segmented, toggle, combobox
- `bulkhead/components/data.css` — table, pagination, item-list, badge, tabs
- `bulkhead/components/navigation.css` — shell-nav, admin-nav and admin sub-components
- `bulkhead/components/layout.css` — progress, modal, page chrome, breadcrumbs, reader-mode
- `bulkhead/components/feedback.css` — status-circle, stepper, stage-bar, truncate
- `bulkhead/components/demos.css` — kitchen-sink-only demo classes
- `bulkhead/components/responsive.css` — `@container` query overrides
- `bulkhead/components/dark.css` — `prefers-color-scheme: dark` overrides
- `bulkhead/rich-text.css` — prose, links, drag-and-drop overrides

Propshaft rewrites each `@import url(...)` to a digested asset URL, so
editing any one piece in isolation is safe.

Bulkhead still accepts `classes:` overrides in its helpers. Those classes are
passed through as-is; custom caller classes must be covered by the host app's
own CSS or by selectors already shipped in the component family files.

### Tone vocabulary

Helpers like `alert(color: …)`, `admin_progress_bar(color: …)`, and
`badge_color_classes(type)` route through `Bulkhead::Tones`, which exposes
two entry points:

- `Tones.normalize!(input)` — strict; returns the canonical CSS-class string
  or raises. Use when a tone is required and there's no fallback (alerts).
- `Tones.coerce(input, allow:, default:)` — validates against a per-component
  allowlist; returns `default` for nil or out-of-range inputs. Use when the
  component supports accent classes (`badge.purple`, `badge.high`) or has a
  sensible fallback (progress bars).

Both entry points are case-insensitive and accept strings or symbols. Add a
new alias in `lib/bulkhead/tones.rb` and every helper picks it up.

`test/css/tone_coverage_test.rb` asserts every tone the helpers can emit has
a matching CSS rule somewhere under `bulkhead/components/` — a smoke test
against drift between the Ruby registry and the stylesheet.

### Post-install

**Kitchen sink routes** (optional, dev-only) — add to `config/routes.rb`:

```ruby
if Rails.env.local?
  resource :kitchen_sink, only: :show do
    member do
      get :buttons, :alerts, :badges, :cards, :tables, :forms,
          :modals, :pagination, :empty_states, :lists, :icons,
          :interactive, :page_headers, :tabs, :layouts, :reader_mode,
          :typography
      post :confirm_demo, :link_demo, :save_demo, :cancel_demo
      get :assignees
    end
  end
end
```

**Admin navigation** — define `admin_nav_sections` in a host app helper to
provide the admin sidebar navigation items. See the `AdminHelper` docs for the
expected format.

**Kitchen sink layout** — defaults to `"application"`. Override with:

```ruby
# config/initializers/bulkhead.rb
Bulkhead.kitchen_sink_layout = "custom_layout"
```

## Day-to-day usage

```bash
bin/bulkhead status                      # Check sync state
bin/bulkhead pull                        # Pull upstream changes
bin/bulkhead push --branch my-feature    # Push changes to a branch
bin/bulkhead push --branch my-feature --pr  # Push and create a PR
bin/bulkhead diff                        # Show local changes
bin/bulkhead diff --upstream             # Show upstream changes we don't have
```

Edit files in `vendor/bulkhead/` directly — it's a regular directory in your
repo. Changes are committed alongside your app code. When ready to share
upstream, use `bin/bulkhead push`.

## Engine architecture

Bulkhead is a **non-isolated** Rails engine. Helpers merge directly into the
host app's helper namespace (e.g., `ButtonHelper`, not
`Bulkhead::ButtonHelper`). This means you can call engine helpers from any view
or helper without qualification.

The engine registers itself through two initializers:
- **Importmap merging** — Stimulus controllers auto-discovered alongside host controllers
- **Propshaft asset paths** — JS, CSS, and vendor assets served by the host's asset pipeline

## Running engine tests

```bash
cd vendor/bulkhead && rake test
```

The engine has its own test suite with a minimal dummy Rails app (no database required).

## Running the kitchen sink in isolation

The dummy app under `test/dummy/` doubles as a runnable Rails app for browsing
the component showcase without a host:

```bash
bundle install
bin/rails server
# then open http://localhost:3000 (redirects to /kitchen_sink)
```
