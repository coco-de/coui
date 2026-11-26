# Tailwind Play CDN — vendored, version-pinned (SPIKE-3 / #3602)

`tailwind-play-3.4.17.js` is a byte-for-byte copy of the script `docs_core/lib/site_head.dart`
loads at `https://cdn.tailwindcss.com`. The parity harness (`tool/parity/`) loads this local copy
instead so it can render with zero network access.

## Provenance

| | |
|---|---|
| Source | `https://cdn.tailwindcss.com/3.4.17` |
| Fetched | 2026-08-01 |
| sha256 | `176e894661aa9cdc9a5cba6c720044cbbf7b8bd80d1c9a142a7c24b1b6c50d15` |
| Confirms | `https://cdn.tailwindcss.com` (unpinned) resolved to the same bytes on the fetch
| | date. `docs_site` loads `https://cdn.tailwindcss.com/3.4.17` — this same pinned
| | release — so the harness runs the exact script the live site runs. |

Note: the script contains its own `console.warn("cdn.tailwindcss.com should not be used in
production...")` — that's a startup warning baked into the minified bundle, not a network call.
`offline_tailwind_harness_test.dart`'s Chrome-based test observes actual requests during render
(0 external ones) rather than grepping the script for the domain name, which is why it does not
assert on that substring.

Re-verify at any time:

```bash
curl -sL https://cdn.tailwindcss.com/3.4.17 | shasum -a 256
# must print 176e894661aa9cdc9a5cba6c720044cbbf7b8bd80d1c9a142a7c24b1b6c50d15
```

## Why vendor the runtime script instead of precompiling static CSS

The harness's job (per `.bmad/architecture-coui-design-parity-motion-verification-2026-08-01.md`,
Component ③ WebCaptureBackend) is to assemble **one self-contained static HTML file per
(component, variant, theme, surfaceStyle) combination**, then screenshot it. Two ways to get
Tailwind's utility classes into that file:

1. **Vendor the Play CDN runtime** (chosen) — the same JIT-scanning script `docs_site` already
   runs client-side. It reads whatever class names are in the DOM at load time and injects the
   matching CSS. Dropping it into a static HTML file needs no build step and no knowledge of which
   classes a given capture will contain ahead of time — the harness only has to inline the script
   next to whatever SSR output `jaspr_test` produced.
2. **Precompiled static CSS** (rejected for this harness) — running the Tailwind CLI/PostCSS ahead
   of time requires either scanning the *whole* component library's source for every capture (slow,
   and easy to miss a class emitted only by a specific resolver branch) or regenerating a
   capture-specific CSS file per combination (a build step per screenshot, working against the
   "single static HTML file, no build step" property that makes this harness self-hosted-safe in
   the first place — see the architecture doc's design note on Component ③).

Vendoring also means the harness runs **the identical script** `docs_site` runs, not a
build-time reimplementation of it — the harness cannot silently diverge from what a user's browser
actually executes, which is exactly the "the verification tool answers differently than the thing
it verifies" failure `⑨ SurfaceFold` was extracted to avoid (see `#3601`).

## Runtime injection order — unchanged from `site_head.dart`

`ThemeConfig.tailwindConfig` returns a `tailwind.config={...}` assignment that has to run **after**
this script, because it assigns onto the global object the script defines
(`docs_core/lib/site_head.dart` carries the same ordering constraint and the same comment). The
offline harness (`tool/parity/src/web/offline_tailwind_harness.dart`) preserves this order:
vendored script → `tailwind.config` assignment → `ThemeConfig.cssVariables`. Confirmed identical
behaviour offline vs the CDN path by `tool/parity/test/web/offline_tailwind_harness_test.dart` —
same computed styles, same `outline-none` compilation (see below), zero network requests observed.

## Why the pinned version matters beyond "it renders"

`web/pseudo-state-emit.md` and `scripts/guards/tokens/check_forced_colors_focus.sh` both assume
Tailwind **v3** semantics for `outline-none`: it compiles to
`outline: 2px solid transparent; outline-offset: 2px` rather than removing the outline
(`outline-style: none`, the v4 meaning). `offline_tailwind_harness_test.dart` asserts this
compiled behaviour directly against the vendored script, so a version bump that silently changes
it fails the harness rather than only surfacing as an unrelated forced-colours bug later.

## Updating this vendor copy

1. Confirm the new version is still v3 (`web/pseudo-state-emit.md`'s reasoning is v3-specific — a
   v4 upgrade needs that doc re-derived first, not just this file swapped).
2. `curl -sL https://cdn.tailwindcss.com/<version> -o tool/parity/vendor/tailwind/tailwind-play-<version>.js`
3. Update the filename reference in `offline_tailwind_harness.dart`, this README's provenance table,
   and (if `docs_core/lib/site_head.dart`'s implicit CDN version also moved) confirm
   `check_forced_colors_focus.sh` still passes.
4. Delete the old versioned file — the harness intentionally has exactly one vendored copy, not a
   history of them, so there is only ever one file for "which version does the harness run" to
   answer.
