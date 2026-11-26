/// Style-slot single entry point for the Web `IndexedSwitcher`.
///
/// Mirrors the Flutter `indexed_switcher_style.dart`: [resolveIndexedSwitcher]
/// walks the nested merge chain
/// (`CoreIndexedSwitcherStyle.defaultX` → `theme.indexedSwitcher.style` →
/// `widget.indexedSwitcherStyle`) and ships back a [ResolvedIndexedSwitcher]
/// paint-ready chrome bundle.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart'
    show CoreCubicBezierToVarCss, durationMsCss;
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedIndexedSwitcher
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `IndexedSwitcher`.
///
/// DOM shape:
///
/// ```text
/// root (<div grid grid-cols-1 h-full>)
///   └─ slot (<div grid-area: 1 / 1>) × n   // every child, in one grid cell
///        └─ child
/// ```
///
/// Every slot shares the one grid cell, so the root is as large as its
/// largest child — the Flutter twin's `IndexedStack` sizing. A hidden slot
/// keeps its box (`visibility: hidden`), which is what keeps it in that
/// measurement, and carries `inert` so it takes no input or focus.
///
/// `indexed_switcher.dart` reads `resolved.<slot>.className` /
/// `.inlineStyles` straight off — no merge / fallback / conversion in the
/// widget body.
class ResolvedIndexedSwitcher implements WebResolvedChrome {
  /// Creates a [ResolvedIndexedSwitcher].
  const ResolvedIndexedSwitcher({
    required this.root,
    required this.shownSlot,
    required this.hiddenSlot,
  });

  /// Paint-ready chrome for the root `<div>` — a single-track grid that adds
  /// no geometry of its own.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the shown child's slot.
  ///
  /// Its fade-in waits out the leaving slot's fade-out, so the two never
  /// show at once.
  final WebElementChrome shownSlot;

  /// Paint-ready chrome for every other slot.
  ///
  /// A slot that has just stopped being shown fades out, then hides; one
  /// that was already hidden stays hidden.
  final WebElementChrome hiddenSlot;
}

// ════════════════════════════════════════════════════════════════
// resolveIndexedSwitcher — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedIndexedSwitcher] for the given [context].
///
/// Walks the merge chain and applies the `CoreIndexedSwitcherStyle.defaultX`
/// static const fallbacks:
///
/// ```text
/// CoreIndexedSwitcherStyle.defaultExitDuration / … / defaultEnterCurve
///   → theme.coreComponentTheme.indexedSwitcher.style
///   → widget.indexedSwitcherStyle
/// ```
///
/// The durations go out through [durationMsCss], so the `--coui-duration-*`
/// variables (and the transition factor for off-scale values) carry the
/// reduced-motion request — the Flutter twin reads the same request through
/// `resolveMotionDuration`.
ResolvedIndexedSwitcher resolveIndexedSwitcher(
  BuildContext context, {
  CoreIndexedSwitcherStyle? indexedSwitcherStyle,
}) {
  final indexedSwitcherTheme =
      context.theme.coreComponentTheme?.indexedSwitcher;

  final merged = resolveStyleChain(const CoreIndexedSwitcherStyle(), [
    indexedSwitcherTheme?.style,
    indexedSwitcherStyle,
  ]);

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final exitDuration = durationMsCss(
    (merged.exitDuration ?? CoreIndexedSwitcherStyle.defaultExitDuration)
        .inMilliseconds,
  );
  final enterDuration = durationMsCss(
    (merged.enterDuration ?? CoreIndexedSwitcherStyle.defaultEnterDuration)
        .inMilliseconds,
  );
  final exitCurve =
      (merged.exitCurve ?? CoreIndexedSwitcherStyle.defaultExitCurve)
          .toVarCss();
  final enterCurve =
      (merged.enterCurve ?? CoreIndexedSwitcherStyle.defaultEnterCurve)
          .toVarCss();

  // ─── Local builders ───────────────────────────────────

  /// The declarations every slot shares: the one grid cell, and a minimum
  /// width that lets a wide child shrink to the track as the Flutter child
  /// does under its parent's constraints.
  Map<String, String> buildSlotBase() => {
    'grid-area': '1 / 1',
    'min-width': '0',
  };

  /// The shown slot — visible at once, opaque after the fade-out it waits
  /// for.
  Styles buildShownSlotInlineStyles() => Styles(
    raw: {
      ...buildSlotBase(),
      'opacity': '1',
      'visibility': 'visible',
      'transition':
          'opacity $enterDuration $enterCurve $exitDuration, visibility 0s',
    },
  );

  /// A hidden slot — fades out, then turns hidden once the fade-out ends,
  /// so its paint leaves with it.
  Styles buildHiddenSlotInlineStyles() => Styles(
    raw: {
      ...buildSlotBase(),
      'opacity': '0',
      'visibility': 'hidden',
      'transition':
          'opacity $exitDuration $exitCurve, '
          'visibility 0s linear $exitDuration',
    },
  );

  return ResolvedIndexedSwitcher(
    root: const WebElementChrome(className: WebLayout.gridTransparent),
    shownSlot: WebElementChrome(
      className: '',
      inlineStyles: buildShownSlotInlineStyles(),
    ),
    hiddenSlot: WebElementChrome(
      className: '',
      inlineStyles: buildHiddenSlotInlineStyles(),
    ),
  );
}
