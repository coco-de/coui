# Flutter Web Liquid Glass refraction

Flutter Web cannot run `ImageFilter.shader`. Its previous navigation lens
animated its shape but fell back to icon scaling rather than bending the
backdrop. This change adds a browser compositor adapter while retaining the
native Impeller path and the shared Core navigation clock.

## Rendering

- DOM Web and Flutter Web generate identical RGBA displacement maps and SVG
  filters from Core. The 8-bit map's neutral value (128/255) receives a matching
  offset correction after displacement, including while strength animates.
  Otherwise a strong pane also translates its flat interior. A colour-transfer
  correction alone is rounded back to 128 in 8-bit filter intermediates.
- An HTML platform view is the Flutter-owned geometry and paint-order anchor.
  Flutter's `clip-path` mutators establish CSS backdrop roots: a filter inside
  them samples transparent black instead of the preceding canvas. The owned
  optical plane therefore sits beside the outer mutator at its scene position.
  Intersecting rectangular/rounded clips are reapplied as SVG paths on that
  plane. Containing and duplicate clips are omitted; ordinary panes retain the
  same CSS rounded mask as DOM Web. Engine-owned nodes/styles are never changed.
- The browser applies the same blur/chroma/refraction chain as DOM Web once
  projection is ready. Until then, or if projection cannot be composed, the
  existing Flutter material remains. Definitions are siblings of the plane;
  defining a referenced filter inside its own filtered element is circular.
- The navigation lens uses its existing position/lift/deformation clock. Maps
  retain their base geometry, with a bounded shared cache; motion changes
  placement, extents and amplitudes without screenshots or per-frame readback.
- Scene mutations update retained-layer placement before browser paint. Only
  changes to the anchor's ancestor styles and structural scene changes trigger
  reprojection; another glass surface's SVG writes do not wake the whole set.
  There is no independent perpetual animation loop. Unmount removes observers,
  planes and definitions.

## Support boundary

Chromium derivatives use the measured SVG backdrop path. Safari, Firefox and
iOS Chrome retain the existing Flutter material because accepting CSS `url()`
does not establish that a browser composites SVG backdrop displacement. The
Jaspr components read the same answer (`surfaceRefractionBrowserSupported`):
where it is false nothing is appended to the surface's `backdrop-filter`, which
keeps the blur and lift its stylesheet states.
Arbitrary path/perspective/rotated clip mutators also retain the Flutter
material. Native platforms keep their original Impeller renderer.

The anchor projection follows Flutter's current web scene structure. The release
browser probe deliberately exercises that integration, so a future engine DOM
change cannot pass solely through shader-free VM tests.

## Verification

`dart test --timeout 5m tool/parity/test/web/flutter_glass_refraction_test.dart`
builds an actual release CanvasKit app, serves local engine assets and compares
captured pixels. It also compiles the shipped DOM Web runtime for the same
background, rectangle and material. PNGs and numerical results are written to
`.dart_tool/flutter-web-glass-proof/` and uploaded by the Chrome CI job.

The checks cover different-bezel displacement with an unchanged flat interior,
a repeated-capture control, full-pane DOM/Flutter pixel parity, icon bending
through the held navigation lens, map reuse, one controlled selection callback,
RTL/refusal, intersecting clips, retained translations, reduced motion, material
changes, transparency accessibility, unmount cleanup and zero writes at rest.
They reuse the existing optical comparison thresholds. Renderer flags, material
recipes, existing goldens, visual tolerances and CI exclusions are unchanged.


Results on Flutter 3.47.5 (the CI SDK): all six release-browser checks pass.
Different-bezel displacement changes 70.56% of the pane; the held navigation
lens changes 87.50% against its independent optical-off control. Full-pane
DOM/Flutter difference is 0% under the existing channel-noise ruler. The
translated/scaled clip and idle/unmount checks also pass. The Widgetbook toolbar,
menu popup and navigation lens were exercised in its real preview container.

Native checks: 60 navigation/refraction tests pass. The full golden + preset
snapshot run has 335 passes and four existing macOS golden failures. Those same
four fail at the unchanged base `a16480e9a`; SHA-256 comparisons of all four
actual PNGs are identical before/after this change. No golden images were
updated. Existing DOM runtime/interaction probes: 27 pass.
