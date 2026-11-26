# Native glass chrome follow-up

Reference: [liquid_glass_widgets/lib/widgets](https://github.com/sdegenaar/liquid_glass_widgets/tree/790521f1138fdba437a383ae56eb502acd9c659a/lib/widgets),
inspected at commit `790521f1138fdba437a383ae56eb502acd9c659a` on 2026-10-21.
This extends the [chrome audit](2026-10-19-liquid-glass-chrome-audit.md) and
[component audit](2026-10-19-liquid-glass-component-audit.md).

The earlier fix removed a backdrop only when callers explicitly cleared an
AppBar. Its ordinary Liquid Glass default still refracted the entire rectangle.
The grouped Widgetbook story hid that difference with a transparent default
material override. This follow-up corrects production defaults and removes
that workaround. Explicit action spacing is forwarded into the capsule.
Both AppBar and labelled ToolbarGroup compose one internal ToolbarGroupSurface;
material/control defaults and Popup composition are no longer duplicated.
The existing surface-ownership and Figma composition guards pass without
changing guard logic or adding exceptions. The generated Figma constants were
refreshed; live Figma Generate/publishing was not performed in this change.

## Source comparison and disposition

| Reference / CoUI family | Finding and result |
| --- | --- |
| `surfaces/glass_app_bar.dart` / AppBar | The reference is a transparent title/layout host. CoUI now gives each contiguous action cluster one persistent capsule, preserves explicit ToolbarGroups and omits empty groups. An authored background remains an ordinary fill. No full-bar optical filter or cast is added. Other material presets keep their existing chrome. |
| `shared/glass_scroll_edge_effect.dart` / AppBar + Scaffold | The reference defaults to a soft graduated edge rather than a refracted toolbar rectangle. CoUI uses a separate contrast gradient; scrolling does not change capsule filter inputs. Floating glass Scaffold headers delegate material even when an AppBar is wrapped in Builder. Explicit Scaffold header colours remain authored surfaces. |
| `interactive/glass_button_group.dart` / ToolbarGroup + Button | The reference distinguishes flexible children from lightweight item mode. CoUI retains flexible children and a single shared optical surface, uses 44-point button defaults without a second padded rim, and suppresses independent icon shrinking. Button instance and project style overrides still win. Plain button borders do not add a box inside the capsule. Individual callbacks, menu triggers, focus and semantics remain on the controls. |
| Centered AppBar titles | Flutter uses NavigationToolbar's symmetric available space. DOM measures the wider action cluster on resize and keeps the title centered in the bar with bounded available width. No continuous geometry ticker or backdrop readback was introduced. |
| DOM material selection | CSS alone cannot add/remove action grouping. A scoped structural builder observes the document material attribute and rebuilds only when that value changes. An explicit local/inherited scope wins. SSR remains request-scoped. The scroll/resize driver is shared across mounted bars and released when the last subscriber unmounts. |
| `surfaces/glass_toolbar.dart` / Menubar, Dock | The reference also deliberately supports rectangular toolbars. Those components are not converted to AppBar-style transparent hosts. Their existing role/material and local panel overrides remain appropriate. |
| Menus, Popover, selectors, pickers | Retain the already-corrected shared Popup material, local override, panel radius, trigger morph and distinct close timing paths. A toolbar capsule does not become a second menu or consume its child's activation. |
| NavigationBar, Tabs, Toggle, Slider | Retain the previous navigation spring/velocity/deformation and resting optics, disabled/RTL selection and gesture lifecycle fixes. No additional motion clock is layered on them. |
| Dialog, Drawer, Modal, Card, Chip, Toast, Tooltip and other SurfaceBlur consumers | Continue to use the shared native/Web material backend and accessibility/depth policies. Passive content surfaces are not given interactive button stretching. The AppBar correction does not remove their optical passes. |

## Validation and boundaries

- Widgetbook: 415 stories across Default/Liquid Glass × Light/Dark, together
  with material switching and interaction checks: **1,676 passed**.
- Native chrome/navigation/overlay regression checks: **28 passed**; DOM chrome: **5
  passed**. Existing default AppBar/Scaffold checks: **59 passed**.
- Core full suite: **3,954 passed**. Web full suite: **5,262 passed**.
  Flutter component/material and non-glass snapshot regression: **392 passed**.
- Release DOM probe confirmed 44×44 and 88×44 action surfaces, 44×44 buttons,
  a centered title, actual SVG displacement filters at rest and after scroll,
  unchanged surface/filter identities, menu activation and live material switching.
  Flutter Web also confirmed actual 44×44 and 88×44 optical planes at rest.
  Only the soft edge rebuilds during Flutter scrolling.
  The edge opacity changes from 0 to .92; high contrast uses an opaque fill.
- Built a SwiftUI system NavigationStack/toolbar reference and the CoUI fixture
  on an iOS 26.5 simulator. Screenshots confirm the transparent host and separate
  left/right capsule structure; this is not a pixel or physics equivalence test.
- The existing Impeller and Chromium refraction implementations are reused.
  No golden baselines, image tolerances, CI exclusions or fallback quality gates
  are weakened.

The reference has additional APIs for size-dependent standalone press growth,
drag stretching, large-title collapse and route transitions. This change does
not claim to implement that entire engine or UIKit. CoUI preserves its authored
bar heights/typography and component contracts. Real-device frame pacing and
platform-view backdrop integration remain separate from simulator/source checks.

Browser probes are in `packages/coui_web/test/fixtures/native_glass_chrome_probe.dart`
and `app/coui_widgetbook/test/fixtures/native_glass_chrome_probe.dart`. The latter
also runs on native Flutter; Widgetbook's ordinary AppBar stories exercise the
production defaults with **Addons → Surface material → Liquid Glass**.
