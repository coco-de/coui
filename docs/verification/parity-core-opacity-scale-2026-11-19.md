# Existing Core opacity scale registration — #5603

Part of [#6131](https://github.com/coco-de/coui/issues/6131). Reuses the existing, unowned [#5603](https://github.com/coco-de/coui/issues/5603); its body/history were preserved. Local product commit: `db59bed679fc6be9af78968b55dca7bf8023df94`, based on main `bad8ebdc8d2c512d216f00c98cb2064f97d51333`.

`CoreOpacity` already defines 21 primitive and five semantic values and documents their Web utility keys. `ThemeConfig.tailwindConfig` omitted the scale, so pinned Tailwind 3.4.17 generated no rules for existing keys such as `opacity-3`, `bg-primary/8` and `active:bg-on-surface/16`. The change registers exactly those 26 key/value pairs under `theme.extend.opacity`, using direct references to `CoreOpacity.scale` and `CoreOpacity` constants. It introduces no design values or arbitrary percentage expansion.

The existing Tailwind defaults remain available, including `35`, `45`, `55` and `65`, which are outside the Core scale. Caller extensions and overrides still compose normally. The rest of the generated configuration is byte identical in all six default/brand/caller × light/dark fixtures after removing the added opacity block. Core defaults, public declarations and global color serializers are unchanged.

## Source and capture binding

The first actual fixtures used base `6ec4d2078eb9dd3844febec56b41493be54fae91` plus this exact ThemeConfig implementation. Main's Loading fix was then integrated normally, with all four owned paths preserved. The ThemeConfig bytes used for the actual after fixtures match product commit `db59bed67` (`3cf35d8cbce5899df6ddd34f8439abf4c7e21790f289db84c22e2ef8fdd0f53d`). Core, Tabs and fixture inputs were unaffected by that integration. The final Chrome suite, docs build/runtime and owned reload ran at `db59bed67`.

The artifact directory is `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-5603-opacity-scale-20261119._5ob_zc8`, also recorded by `/tmp/weever-opacity-scale-path`. Its `final-source-binding.json`, `source-contract.json`, `source-closure.json`, `main-integration-receipt.json` and raw fixtures retain the exact binding. The paired JSON report contains the checks and selected original image hashes.

## Results

| Check | Result |
| --- | --- |
| ThemeConfig suites, including new scale contract | 143 passed |
| Actual Chrome utility tests, default/brand/caller × L/D | 6 passed |
| Existing Loading compatibility tests after main integration | 47 passed |
| Actual before/after browser data | 12 pages, 1,860 raw target rows, zero runtime/request errors |
| After utility values | 910 valid opacity/background/text/border/ring checks, zero failures |
| Existing Core rules missing per default/brand page | 45 before → 0 after; nine keys × five targets |
| Caller pages already defining key `8` | 40 missing rules before → 0 after |
| Inherited Tailwind-only default pairs | 120 exact |
| Caller override/addition pairs | 20 exact |
| Actual Native opacity and color inputs | 52 rows, matching after-Web opacity and RGBA8 values |
| Actual inactive Tabs, pill/underline × L/D × rest/hover/pressed | 12 Native + 24 before/after Web rows; after color inputs exact |
| Inactive Tabs sampled paint | Maximum channel difference 34 before → 1 after, retained as observed |
| Fresh optimized docs build | 359 unique routes, O2, 132.01 s, exit 0 |
| Docs build tracked source protection | 22,560 files, byte/mode deltas 0 |
| Actual `/components/tabs/` | L/D rest/hover/pressed + refresh, eight records, zero runtime/request errors |
| Public declaration shapes / package config tuples | 24 / 232 exact |
| Fatal analysis / format / full contract guard | Passed; existing seven non-enforced migration warnings retained |
| Owned VM reload | Success; before/after HTTP 200 and exact utility HTML; HTTP/VM/PID closed |

The 1,860 rows include before and after fixtures. Of 930 after targets, 20 deliberately use the caller-only key without caller configuration; these remain undefined and visible in the raw data. The report therefore counts 910 valid value checks. No official matrix fields or skip conditions were changed.

The Native tests load the repository's parity fonts and use `CoreFontFamily.sans`. Utility fixtures use a white canvas in both token themes. Native/Web full control allocations differ; the Tabs checks compare the actual inactive paint owner, input color and recorded interior sample. They do not certify whole-image geometry or glyph equality.

## Boundaries and retained negatives

Selected pure-token Tabs base-fill composition is a separate known issue. Registering the scale does not fix it. The one-channel sampled paint differences are retained; no threshold, normalizer or comparator was relaxed. This issue performs no global 816 capture/report and makes no reduction claim against historical `582/234` or legacy Tabs entries.

Only `packages/coui_web/lib/src/base/theme_config.dart` changes in production. Core/Native, original Markdown, docs rendering source/CSS/JS, public signatures, dependencies/locks and parity producer/model/normalizer/comparator/criteria/skip/baseline remain unchanged from base main. The permanent tests exercise the generated config and actual pinned Tailwind CSS, including inherited defaults, brand tokens and caller composition.

Original compile/setup failures are preserved: the fixture initially used non-constant record accessor expressions in a const map; CDP's partial Proxy preview initially hid named config keys; an API helper initially used an older analyzer AST. Corrections use a final Core reference map, a plain JSON snapshot of the Proxy, and analyzer 14.7 declaration tokens. No expected keys were removed.

The first owned reload succeeded but a full Tabs HTML assertion differed only in generated IDs; the exact diff remains. A stable utility owner then verified reload and exact HTML without stripping IDs. The docs helper's initial compile failure and original full-content screenshots also remain; final screenshots use explicit actual viewport coordinates, without image editing.

Eight original PNGs were viewed and selected with precise captions in `selected-evidence.json`. All recorded 37 process checks and six port checks were closed. The branch/worktree and all before/raw/log evidence are retained. This worker created no PR and pushed no product changes.
