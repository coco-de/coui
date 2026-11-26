# Scrollbar repair and release validation

A layout-driven scroll-start notification could rebuild the scrollbar's
accessibility subtree during the persistent frame callbacks. The repair
coalesces reports until the frame ends; newer safe updates supersede queued
reports, and hidden thumbs retain their accessibility values and actions.
The regression is coco-de/coui#6268, observed in Cocode's real Quick Fix flow.

The full CI surfaced existing main-branch release-gate failures. The Web
AppBar now calls ResizeObserver.observe through a callback: dart2js rejects
the external JS interop method tear-off. A real Chrome test covers the actual
measurer's root text-size changes, observed cluster resize and disposal.
Measured CSSOM lengths stay in CSS pixels through an internal converter;
rem conversion would apply text scale twice. The converter is hidden from
the public barrel. The NavigationBar rail's zero gap now routes through
spaceCss(CoreSpace.space0). Public colour-distance tests exercise neutral
endpoints, symmetry and alpha handling without removing the published
CoreColorDifference API or resetting guard baselines.

## Preset snapshots

CI at d97048a3c7 failed four Toggle render-tree snapshots: defaultStyle,
neoBrutalism, claymorphism and neumorphism. The other 291 tests passed.
A separate unmodified main checkout at
e3ab376d333ad5c8364e7021e9daad6d41c61a23 reproduces the Toggle
mismatches in a separate checkout. The differences are the white thumb and its preset-resolved shadow
already introduced by merged commit15b87c1f47b78148bd3dc52e73e645aa82d4615b
(PR #6286), followed by disabled-thumb alignment in PR #6295.

The four stale structural JSON entries are synchronized with that accepted
main-branch change. Parsed before/after verification proves that in each file
only the Toggle entry changes, only one circle node changes, and its only
changed fields are fill and shadows. All other surfaces and metadata remain
identical. A normal run, without UPDATE_PRESET_SNAPSHOTS, passes 295 tests.
These are CoUI render-tree snapshots; Cocode's frozen 256 Figma PNGs and its
zero-tolerance whole-image RGBA thresholds are untouched.

## Checks

Full CI at b69df59a1c passed the static guards and all Flutter analysis,
API and preset checks, but docs_core rejected two page IDs absent from the
canonical plugin structure capture. In accordance with the library map's
existing provenance rule, NumberInput and Sidebar now link to the canonical
file and name the page without asserting an unverified node ID. The original
plugin capture and the regression test remain unchanged.

- Flutter 3.47.9 / Dart 3.13.7: 166 scrollbar tests pass.
- 149 Web app-bar/navigation/CSS tests and 74 public-colour/palette tests pass.
- One actual Chrome AppBarSideMeasurer browser test passes.
- 295 preset-render checks pass against the reviewed four-entry update.
- Scoped fatal-info analysis, token CI step and exported-symbol ratchet pass.
- Independent Cocode preflight at temporary dependency bff96ef980 passes 576
  UI tests, including its existing control golden, plus 27 plan/deployment
  tests. The preflight copies 12 translation outputs from the identical
  Cocode source checkout; it does not commit generated files.

Release adoption is verified separately in Cocode. The product will pin
Flutter/Core to one released commit
containing the repair and repeat its full visual/functional/native checks.
No product merge or gallery deployment is claimed before its complete strict
Figma goal. Full remote CI and the subsequent package tags remain separately
recorded on PR #6270 and the release PR.
