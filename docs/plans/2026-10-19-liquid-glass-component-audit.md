# Liquid Glass component integration audit

Date: 2026-10-19. Scope: Flutter component motion and existing material rendering paths. This extends the navigation investigation to shared infrastructure and its consumers; it is not a claim that every component was visually compared with UIKit.

## Changes by shared path

| Path | Consumers and result |
| --- | --- |
| Navigation motion | A single ticker coordinates rendered position, velocity-dependent deformation and optical activation. Retargeting and release retain velocity; quiet selection remains after the lens settles. |
| Clickable | Button, Chip and other clickable consumers now share one feedback clock for scale, translation and shadow. Live reduced motion ends feedback without replacing content or focus state. |
| AnimatedValueBuilder | Switcher, Window, Toast and other transition consumers resolve reduced motion consistently. Retargeting captures the previous interpolator's visible value; unrelated rebuilds retain the raw transition start. Completion callbacks remain attached across curve changes and discard stale transitions. |
| OutlinedContainer and ModalContainer | Switching to zero motion finishes an already-running chrome transition. Stable child subtrees preserve content state and focus; the outer SurfaceBlur state survives. Restoring motion restores normal transitions. |
| Toggle, Slider and Tabs | Toggle optics follow the rendered thumb. Slider redraws its local preview, closes cancelled gestures and rejects read-only gestures. Tabs skip disabled destinations and respect RTL. |
| AppBar and Popover | Transparent AppBars avoid a redundant full-width blur. Popover close timing uses the close duration; morph surfaces honor local material overrides and resolved corner geometry. |

The shared SurfaceBlur path, nested surface handling, material roles and component-local SurfaceTheme overrides were inspected. Existing surface inventory guards cover the broader component declarations and wiring. Components that already use these paths inherit the fixes without an additional backdrop pass or a permanent animation ticker. Source inventory is distinct from individual visual testing.

Slider currently owns no material role. This patch fixes its gesture lifecycle without introducing a Flutter-only glass appearance contract. Vertical or mixed-width navigation retains its existing fallback behavior. No new public component API or Core/Web style contract is introduced.

## Validation

- Flutter functional suite: `flutter test --no-pub --exclude-tags parity,golden` — 7,252 passed.
- Final ModalContainer and navigation regression run: 18 passed, covering edits completed after the full suite began.
- CI-mode golden image suite: 44 passed without baseline changes.
- `dart analyze . --fatal-warnings`: passed, no errors or warnings; informational diagnostics remain.
- Animation lifecycle, implicit curve, Flutter surface contract, surface role, stroke suppression, fill contract, directional inset and rule-writing guards passed.
- Separate reports record the [navigation evidence](2026-10-19-liquid-glass-motion-analysis.md), [selector coverage](2026-10-19-liquid-glass-selector-audit.md) and [chrome coverage](2026-10-19-liquid-glass-chrome-audit.md).
- The macOS Impeller preview accepted a hot restart and reported no runtime errors.

The source reference is pinned in the navigation report. REA binary inspection succeeded, but its native UI observation was blocked by unavailable process identity. Screenshots and Flutter runtime inspection used separate tools. Neither automated 60/120 Hz simulation nor macOS preview establishes iOS device FPS or visual equivalence with Apple controls.
