# Bulkhead

A reusable Rails engine providing the view layer — helpers, Stimulus
controllers, Tailwind design tokens, and shared partials.

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
- **Tailwind design tokens** — semantic color system (primary, danger, success,
  warning, info) + prose variants
- **Vendor assets** — dragula (drag-and-drop), air-datepicker

## Requirements

- Rails 8.0+
- Propshaft + Importmaps (no Webpack/esbuild)
- Tailwind CSS 4+ via `tailwindcss-rails` (>= 4.3.0 for engine support)
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

# 3. Run the install script (patches Gemfile and application.css, bundles)
bin/bulkhead install
```

The install script:
- Adds `gem "bulkhead", path: "vendor/bulkhead"` to your Gemfile
- Adds `@import "../builds/tailwind/bulkhead"` to your `application.css`
- Creates `bin/bulkhead` symlink if missing
- Runs `bundle install`

### How Tailwind integration works

Bulkhead uses `tailwindcss-rails` experimental engine support. The engine
provides `app/assets/tailwind/bulkhead/engine.css` which contains `@source`
directives pointing to its own views, helpers, and JS files. On build,
`tailwindcss-rails` auto-generates a build file at
`app/assets/builds/tailwind/bulkhead.css` with an absolute-path `@import` to
the engine's CSS. No symlinks needed.

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

Tailwind CSS class scanning is handled entirely by `tailwindcss-rails` via the
engine's `app/assets/tailwind/bulkhead/engine.css` entry point.

## Running engine tests

```bash
cd vendor/bulkhead && rake test
```

The engine has its own test suite with a minimal dummy Rails app (no database required).
