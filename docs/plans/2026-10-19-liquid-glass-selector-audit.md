# Liquid Glass selector audit — 2026-10-19

Scope: Flutter Toggle, Slider, Tabs, and Switcher. Reference reviewed:
`sdegenaar/liquid_glass_widgets`, especially `glass_switch.dart` and
`glass_slider.dart`, from the checked-out reference in
`/tmp/coui-liquid-glass-reference-20261019`. This audit uses the reference to
identify interaction and lifecycle requirements; it does not copy its shader,
public API, or numeric tuning.

The reference keeps the switch's rendered thumb position available through an
interrupted transition. A material overlay must follow that rendered position,
not independently interpolate the two nominal endpoints. Gesture completion and
cancellation must also leave controls in a settled state.

| Component | Current material ownership | Finding and change |
| --- | --- | --- |
| Toggle | Content track through OutlinedContainer; transient functional lens; opaque thumb | The thumb retargeted from its current position but the lens restarted at a resting endpoint on rapid reversal. The lens now follows the actual composited thumb position. Enabling reduced motion stops an existing lens; an external value change also cancels the user-only lens. |
| Slider | Plain track and thumb with explicit colors; no owned material role | Local drag changes depended on host rebuilds; cancelled drags left the local preview active; a missing onChanged still accepted drag lifecycle callbacks. Local preview now redraws immediately, cancellation settles to the controlled value and closes the drag, and read-only controls accept no gestures. |
| Tabs | Content surface for a filled pill container; underline variant has no surface fill | Material already forwards blur, saturation, brightness, sheen and refraction. Swipe navigation ignored disabled destinations and reading direction. It now skips disabled destinations and honors RTL. |
| Switcher | Layout/content transition only, no owned material surface | It uses AnimatedValueBuilder, which resolves reduced motion and retargets from the current rendered value. Material belongs to child surfaces. No additional backdrop pass is introduced. |

The current Liquid Glass recipe supplies glass to both content and functional
roles. The distinction above describes component ownership, not a rule that
content is opaque. Nested surface depth remains handled by existing resolvers.

Slider is **not** newly described as a glass control by this patch. Adding a glass
thumb would require an explicit shared Core/Web material contract, rather than
silently making a Flutter-only appearance change. Likewise, this audit does not
claim that Toggle or Tabs reproduce UIKit's complete interaction physics.

Validation: 110 tests passed across Toggle, Slider lifecycle/anchoring/focus/
keyboard, Tabs and Switcher. New regressions cover rapid switch reversal, reduced
motion during a lens transition, cancelled slider drag, read-only slider gestures,
and disabled-tab skipping in both text directions. Targeted analysis has no
errors or warnings; three existing informational lints remain in the Slider and
Toggle chain/controller declarations. No iOS device frame-rate measurements were
performed for these selectors.
