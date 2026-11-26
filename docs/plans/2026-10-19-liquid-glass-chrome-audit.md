# Liquid Glass chrome audit — 2026-10-19

Scope: Flutter AppBar, Popup, Menu, Menubar, ToolbarGroup, DropdownMenu,
ContextMenu, Popover (including its composed selectors and pickers), Dialog,
Drawer, and ModalContainer. Navigation motion and interactive form controls
are covered separately.

Reference: `sdegenaar/liquid_glass_widgets`, locally inspected at
`/tmp/coui-liquid-glass-reference-20261019`. Its `GlassAppBar` deliberately
keeps the bar itself transparent and places glass on individual controls or
capsules. This supports separating material ownership instead of stacking a
full-width glass pass beneath already-glass toolbar groups. No reference code
was copied; this is a behavior and architecture comparison, not a claim of
UIKit equivalence.

| Surface | Finding and disposition |
| --- | --- |
| AppBar | Explicit transparent fill still installed a full-width backdrop/refraction pass. Removed that pass; scroll-edge transient zero opacity retains its existing stable filter. |
| ToolbarGroup | Composes one horizontal Popup; empty groups are omitted. Its glass now remains the only backdrop in a transparent AppBar. |
| Popup / Menu | Local material, transparent inline-submenu suppression, optical profile, reduced-transparency fallback and motion durations already resolve through shared paths. No duplicate local implementation added. |
| Menubar | Local material forwards into menuPanelStyle; panel-specific override wins. Overlay already uses distinct resolved open/close durations. Geometry rim/cast correctly remains on the independent geometry axis. |
| DropdownMenu / ContextMenu | Compose Menu/Popup and pass distinct resolved open/close durations to shared overlay. Pointer-anchored context menus have no measured trigger to morph from. Existing semantics and placement retained. |
| Popover | Morph previously read the page material, so a locally glass panel did not morph and an opaque local opt-out could still morph. Internal overlay now receives panel style and resolves the same material chain. Morph radius now follows the actual popup radius. |
| Popover close | Resolver supplied a separate close duration but the widget forwarded the open duration for dismissal. Corrected the forwarding. |
| Selectors / pickers using Popover | Inherit the corrected local material, radius and close timing through composition. |
| Dialog / Drawer | Their functional material and resolved motion paths are already shared; per-subtree SurfaceTheme works through captured themes. No automatic interactive bubble added to passive large panels. |
| OutlinedContainer / composed Chip | An already-running implicit chrome animation survived a live change to reduced motion. A private chrome wrapper replaces only animation state on zero-duration mode changes, retaining the content subtree, focus and enclosing SurfaceBlur state. Normal Flutter container interpolation and existing widget types are preserved. |
| ModalContainer | Its AnimatedContainer bypassed reduced-motion resolution. Routed transition durations through resolveMotionDuration, and added private chrome-state replacement for a preference change during animation; content, focus and SurfaceBlur state survive. |

Regression checks live in `liquid_glass_chrome_test.dart`, together with the
existing AppBar, liquid-glass menu, popover morph and popover lifecycle suites.
These prove material ownership, configuration propagation, reduced motion and
lifecycle timing. They do not measure iOS device frame pacing or establish a
pixel/physics match with Apple's implementation.

`outlined_container_live_motion_test.dart` also checks a live accessibility
change during a glass chip press and directly verifies painted decoration,
layout, preserved content state, focus, shader host state, and motion resuming
when the preference is removed.

`modal_live_motion_test.dart` verifies the same live preference behavior for
ModalContainer, including immediate painted-color settlement and normal motion
resuming when reduced motion is turned off.
