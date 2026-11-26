# Web / Flutter Liquid Glass interaction parity

## Result

Navigation now shares `CoreGlassNavigationMotion` between Flutter's ticker and
Web's requestAnimationFrame clock. The position, velocity-preserving retarget,
release, lift, speed/acceleration deformation, edge resistance and reduced-motion
policy follow the same numbers. Restoring motion while a pointer is held
resumes the same material clock on both platforms. Web keeps committed accessibility selection
separate from the lens preview and dispatches one selection on drag release.
Disabled targets, controlled refusal, RTL, external selection and unmount cancel
or settle the gesture safely. The frame clock stops at rest.

The Web lens uses the shipped SVG refraction runtime, cached geometry maps and
animated displacement amplitudes. Its optics ease in with activation; maps are
not regenerated for every animation frame. The quiet selection remains visible
at rest. The bar backdrop is a separate plane beneath the contents and lens;
placing its backdrop filter on their ancestor would trap the lens sampling
inside that backdrop root and could render an opaque white capsule. A real
colored-backdrop pixel probe guards this layer ordering. Tooltip hit areas fill their navigation cells. Unequal/overflowing
items retain their individual selection backgrounds, as Flutter does when its
row cannot fill with equal cells.

The shared Web surface host also detects framework rewrites that remove its
inline refraction/rim bindings while retaining the same element id. It reattaches
against the newly authored blur instead of silently dropping refraction or
restoring a stale material. Style observation is limited to tracked surfaces, so
an unmarked navigation lens's frame updates do not rescan the document. This
reaches all components using the shared surface markers. Hidden/unmeasured
surfaces create no empty SVG hosts and do not repeatedly bind. ResizeObserver
attaches their optics when they become measurable; new authored blur values
remain intact while hidden and after showing.

Other corrected differences:

- Toggle: lens travel uses the thumb's actual Web Animations timeline and its
  computed reversal keyframes. Independent endpoint keyframes previously jumped
  during rapid reversal. Explicit border-box sizing makes a 40×20 Core track
  measure 40×20 on Web, rather than 44×24 after padding.
- Popover: morph eligibility and radius come from the fully resolved local panel
  style. A runtime-owned clip rule survives the positioner's inline style
  updates, which previously erased the clip between animation and paint. Live
  reduced motion removes the clip. This shared fix also reaches other users of
  `LiquidMorphClip`.
- Transparent AppBar: an explicitly zero-alpha background does not acquire a
  full-width material pass. Grouped toolbar surfaces retain their own material.
- Tabs: fractional touch coordinates, disabled-tab skipping, RTL, vertical
  scrolling, multi-touch/cancel and caller event composition are handled.
- Slider: local drag preview renders immediately without host echo; disabling,
  range changes and disposal detach document listeners. End/cancel closes once
  and clears preview even without an `onChangeEnd` callback.

## Verification

- Core functional suite: 3,947 passed, including new continuity, 60/120 Hz,
  deformation, reduced-motion and background-pause cases.
- Web suite: 5,256 passed.
- Flutter navigation/gesture regressions: 31 passed.
- Flutter existing goldens: 44 passed, without updating images.
- 19 real Chromium interaction cases and the existing optical probes exercise
  the shipped client
  components with animation enabled, including rapid toggle reversal and local
  popover material changes and live root font-size scaling. Measured CSS pixels
  convert through the live rem size, preserving geometry at enlarged text sizes. The VRT animation freeze remains unchanged.
- API synchronization, resolver/contract guards and fatal-warning analysis run
  alongside CI. No CI thresholds, visual tolerances, allowlists, shader quality
  or material recipes were reduced for this change.

## Renderer limits

The motion and interaction contract is shared; CSS/SVG and Flutter/Impeller are
separate renderers. Chromium exercises the Web displacement path. Browsers that
do not composite SVG backdrop displacement retain their material fallback.
Web scales its cached lens maps with the moving capsule, while Flutter computes
shader bounds at the animated size. This is not a claim of pixel identity across
engines or measured 120 FPS on iOS hardware. No connected iOS device performance
measurement was available for this change.
