# Iconify — vendored, version-pinned (#3605)

`iconify-icon-2.1.0.js` and `lucide-1.2.121.json` let the offline capture harness
(`tool/parity/src/web/web_capture_backend.dart`) render CoUI `Icon` components (`<iconify-icon>`)
with zero network access.

## Why this exists

`docs_core/lib/components/icon/icon.dart`'s `Icon` renders `<iconify-icon icon="lucide:home">`.
`docs_core/lib/site_head.dart` loads the *custom element definition* from a CDN
(`https://cdn.jsdelivr.net/npm/iconify-icon@2.1.0/dist/iconify-icon.min.js`, the same version
pinned here) — but that script alone does **not** draw anything. Confirmed by hand: loading only
the script offline produces an empty shadow root (`<style>...</style>`, no `<svg>`). The custom
element's default behaviour is to fetch the actual icon path data from Iconify's live API
(`api.iconify.design`) at render time — the same "phone home for pixels" problem the Tailwind Play
CDN vendor copy (`../tailwind/README.md`) solves for utility CSS, but for icon SVGs instead of
classes.

The fix is the same shape: vendor what the network call would have returned, and register it
locally before any `<iconify-icon>` element connects.

## Provenance

| | |
|---|---|
| `iconify-icon-2.1.0.js` source | `https://cdn.jsdelivr.net/npm/iconify-icon@2.1.0/dist/iconify-icon.min.js` (same version `docs_core/lib/site_head.dart` loads) |
| `iconify-icon-2.1.0.js` sha256 | `758d94838db0cafdeb97eb0b54a120de36cfb3c7fe862eed989f37e80c550f02` |
| `lucide-1.2.121.json` source | `https://cdn.jsdelivr.net/npm/@iconify-json/lucide@1.2.121/icons.json` |
| `lucide-1.2.121.json` sha256 | `428633667745fc16b264451b5d9bab478e7a648720a7d40c01e756b21346fe97` |
| Fetched | 2026-08-01 |

Only Lucide is vendored: `code-style/naming.md` restricts *shipped component* chrome icons to
`LucideIcons` exclusively, and a repo-wide check at vendoring time found zero
`RadixIcons`/`BootstrapIcons`/`HeroIcons` references in `docs_core/lib/previews/examples/web/`
(the source every capture actually renders). A future example that introduces a second icon set
needs a second vendored collection alongside this one — the harness does not silently degrade for
an unvendored prefix, it captures a blank icon (see "What happens for an unvendored icon" below).

Re-verify at any time:

```bash
curl -sL https://cdn.jsdelivr.net/npm/iconify-icon@2.1.0/dist/iconify-icon.min.js | shasum -a 256
curl -sL https://cdn.jsdelivr.net/npm/@iconify-json/lucide@1.2.121/icons.json | shasum -a 256
```

## How registration works — `customElements.get('iconify-icon').addCollection(...)`

The minified bundle does **not** expose a global `window.Iconify` object — `addCollection` (along
with `loadIcons`, `calculateSize`, etc.) is attached to the `<iconify-icon>` custom element class
itself. Confirmed by hand: calling `window.Iconify.addCollection(...)` silently no-ops
(`window.Iconify` is `undefined`); the element only renders real SVG content once registered via:

```js
customElements.get('iconify-icon').addCollection(<lucide collection JSON>);
```

This call must run in a `<script>` that executes **after** the `iconify-icon-2.1.0.js` script (so
the class is defined) and **before** the harness `<body>` is parsed (so every `<iconify-icon>`
element resolves the collection on its first `connectedCallback`, not a later re-render that never
happens for a static capture page). `tool/parity/src/web/local_icons.dart`'s
`buildLocalIconifyHeadHtml()` emits the runtime and registration in that order,
with CoUI's `packages/coui_web/lib/iconify_stroke.js` companion between them.
That same shipped companion normalizes a copy per unbundled Lucide instance;
the vendored collection remains canonical, with authored stroke 2. The companion
uses Iconify's own loader/cache and icon-data API for all rendering modes.

## What happens for an unvendored icon

`addCollection` only registers the `lucide` prefix. An icon from an unregistered prefix (or a
genuinely unknown Lucide icon name) renders an empty shadow root — no error, no console warning
users would see in a headless run, just a blank glyph exactly like the un-vendored state this file
fixes. There's no drop-dead assertion in the current harness for this — a wrong icon name looks
identical to a missing collection in the captured PNG/JSON either way. Widening the check (compile
manifest icon names against the vendored collection's `icons` keys ahead of a capture run) is a
reasonable finding for a future PR, not part of #3605's own completion definition.

## Updating this vendor copy

1. `curl -sL https://cdn.jsdelivr.net/npm/iconify-icon@<version>/dist/iconify-icon.min.js -o tool/parity/vendor/iconify/iconify-icon-<version>.js`
2. `curl -sL https://cdn.jsdelivr.net/npm/@iconify-json/lucide@<version>/icons.json -o tool/parity/vendor/iconify/lucide-<version>.json`
3. Update the filename constants in `tool/parity/src/web/local_icons.dart` and this README's
   provenance table.
4. Delete the old versioned files — exactly one vendored copy of each, matching the Tailwind
   vendor directory's convention (no history of prior versions sitting alongside the current one).
5. Re-run `tool/parity/test/web/local_icons_test.dart`'s Chrome-based test to confirm a real icon
   still renders non-empty SVG content offline.
