# Liquid Glass navigation motion: source analysis ledger

Date: 2026-10-19. Scope: improve CoUI's existing Flutter navigation indicator from independently implemented motion principles. This document records source evidence and implementation intent; it does not establish visual equivalence with UIKit.

## Reference and provenance

Reference repository: [sdegenaar/liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets), pinned revision [`730e4a97c6fcb33c8e907715731b2cd7b7932438`](https://github.com/sdegenaar/liquid_glass_widgets/tree/730e4a97c6fcb33c8e907715731b2cd7b7932438). All source locations below refer to that revision.

The repository uses the MIT license, copyright Sebastian Degenaar. Its engine and draggable-indicator physics acknowledge MIT-licensed work by Tim Lehmann / whynotmake-it. This change uses independently written CoUI code rather than copying reference source. Any future substantial source port must preserve the applicable notices.

## Observed source mechanisms

| Evidence | Mechanism | Relevance to CoUI |
| --- | --- | --- |
| `lib/utils/glass_spring.dart:128–149,176–219` | Retargets a `SpringSimulation` from its current value and velocity; ticks until the simulation settles. | Preserve continuity when the pointer changes direction or the target changes mid-flight. |
| `lib/src/widgets/surfaces/tab_bar_bottom_internal.dart:634–642`; `lib/utils/glass_spring.dart:471–497` | Uses different tracking and release spring descriptions without snapping on release. | Fast tracking and elastic settling can share one motion state. |
| `lib/src/widgets/surfaces/tab_bar_bottom_internal.dart:689–695`; `lib/utils/draggable_indicator_physics.dart:100–138` | Drives capsule deformation from the velocity of the rendered position spring. | Shape should respond to visible motion, including the release tail, rather than pointer-event frequency. |
| `lib/src/widgets/surfaces/tab_bar_bottom_internal.dart:649–664` | Keeps the material active while pressed, dragging, or sufficiently separated from its target. | Avoid removing refraction while the indicator is still settling. |
| `lib/widgets/shared/animated_glass_indicator.dart:337–410` | One thickness signal expands the indicator, fades the resting fill, and controls lens visibility. A softened pinch signal limits UV jitter near full activation. | Coordinate material and geometry; avoid amplifying spring oscillation into unreadable icon distortion. |
| `lib/src/widgets/surfaces/tab_bar_drag_gesture_mixin.dart:181–198` | Reconciles the visual target with the selection accepted by the host. | Preserve controlled-component behavior when navigation is declined. |

The actual active-lens defaults at `animated_glass_indicator.dart:183–202` are transparent fill, thickness 20, refractive index 1.10, zero chromatic aberration, and zero blur. Nearby comments contain different historical values; the literals are the evidence. These parameters belong to that renderer and are not interchangeable with CoUI shader coefficients.

The reference shader also contains touch-position-dependent rim lighting (`shaders/liquid_glass_render.frag:772–829`). That establishes shader capability, not proof that every navigation path supplies a moving touch position. Dynamic lighting is separate from the motion changes described here.

## CoUI implementation direction

- Use a single ticker and continuous position/velocity state backed by `SpringSimulation`. Retarget from the rendered state rather than restarting fixed-duration easing on every event.
- Use near-critical fast following during a drag and underdamped release settling. This is a deliberate CoUI choice: the reference's interactive preset also has some bounce.
- Derive deformation from the same rendered velocity, allowing speed changes, reversals, and release motion to affect the capsule coherently.
- Keep optics active while the pointer is held or the motion is settling, then return to the quiet resting selection. The shared lens owns press deformation; disable the separate per-item shrink feedback for this glass track so it does not fight lens magnification or continue on an independent animation clock.
- Apply smooth, saturated visual resistance beyond the end items while keeping logical selection within valid bounds.
- Preserve controlled selection callbacks, disabled-item handling, RTL coordinates, cancellation, and reduced-motion behavior.

The reference is not copied wholesale. Its edge resistance is piecewise linear with a hard cap despite a broader description in comments. Its bar sway uses per-event displacement rather than displacement divided by elapsed time. Its release handler uses finger velocity to choose a target, while the animation preserves spring velocity. Its jelly transform remains a scaled capsule rather than a fluid simulation. These distinctions inform the CoUI implementation and prevent treating the package's native-parity comments as verified facts.

## REA evidence and validation limits

REA `open_binary` succeeded for the CoUI preview binary with SHA-256 `cfccdec5995562dac46ae0cb453c80054a7441bae28cbeb0fabde8f9bb336723`. A subsequent `observe_native_ui` attempt for PID `97603`, window `12831`, was blocked with `process-identity-unavailable` because launch-time process identity was unavailable. Consequently, this investigation obtained **no REA visual evidence** from that attempt. Opening a binary does not verify rendered behavior.

The source findings above support the design changes, not a claim of identical Apple behavior. Apple-equivalent motion and iOS device frame-rate performance remain unestablished. Validation must distinguish automated behavior and continuity checks from visual comparison against the supplied recordings and on-device frame timing.

## Automated validation

`flutter test --no-pub test/components/liquid_glass_navigation_gesture_test.dart --reporter expanded` passed all 17 tests. Coverage includes release-tail lens visibility, held and moving geometry, reversal and re-grab continuity, host-declined selection, smooth bounded overscroll in LTR and RTL, cancellation, disabled items, external item changes, and secondary-pointer exclusion. Enabling reduced motion during either a held drag or release settling removes the lens, restores resting geometry, and stops ongoing animations.

A matched timed trajectory compares 60 Hz and 120 Hz simulations through forward travel, reversal, and a pause. At matching 100 ms checkpoints it allows 6 logical pixels of position difference and 2 logical pixels of size difference for discrete input sampling. This checks motion consistency across simulated frame rates; it does not measure actual rendering FPS, GPU cost, or Apple visual equivalence.

The related navigation/menu suite passed 253 tests with `flutter test --no-pub test/components/navigation test/components/liquid_glass_navigation_test.dart test/components/liquid_glass_menus_test.dart test/components/navigation_bar_selection_signal_test.dart`. That broader run preceded the final change assigning press feedback exclusively to the shared glass lens; the 17 gesture tests above passed after that change. Repository guards for animation lifecycle, implicit curves, directional insets, design phases 6 and 7, and rule writing also passed.

A macOS Impeller preview was hot-reloaded without reported runtime errors, and ordinary screenshots showed the press geometry and lens. This is separate from the blocked REA observation and is not an iOS reference comparison.
