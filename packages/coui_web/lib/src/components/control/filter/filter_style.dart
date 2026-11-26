/// Style-slot single entry point for the Web `Filter`.
///
/// `resolveFilter` walks the merge chain
/// (`CoreFilterStyle.defaultX` → `theme.filter.style` →
/// `theme.filter.variantStyles[variant]` → `component.filterStyle`) and
/// ships back a [ResolvedFilter]. The segments are a composed
/// `ToggleGroup`, so this resolver does not emit the track or the
/// segments: it raw-forwards [ResolvedFilter.toggleGroupStyle] and emits
/// only the trailing part — the row that holds the hairline and the reset
/// button.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedFilter — slot-only chrome bundle
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Filter`.
///
/// DOM shape:
///
/// ```text
/// ToggleGroup (toggleGroupStyle)                 // track · segments · chosen face
///   └─ trailing                                  // * showResetButton && onReset != null
///        root (<div inline-flex>)                // row, gap = trailingSpacing,
///                                                //  inline-start room = dividerLeadingSpacing - the group's item gap
///          ├─ dividerBox (<div>)                 // fixed dividerHeight
///          │    └─ Divider.vertical (dividerStyle)
///          └─ Button.ghost·sm·square (resetButtonStyle)
///               └─ Icon(resetButtonStyle.leadingIconStyle)
/// ```
///
/// `root` is the outermost element `Filter` itself owns — the trailing row.
/// The track and the segments belong to the composed `ToggleGroup`, whose
/// own resolver turns [toggleGroupStyle] into chrome.
class ResolvedFilter implements WebResolvedChrome {
  /// Creates a [ResolvedFilter].
  const ResolvedFilter({
    required this.root,
    required this.dividerBox,
    required this.toggleGroupStyle,
    required this.dividerStyle,
    required this.resetButtonStyle,
  });

  /// Chrome for the trailing row `<div inline-flex>` — the hairline and the
  /// reset button, `trailingSpacing` apart.
  @override
  final WebElementChrome root;

  /// Chrome for the box that gives the hairline its length (`dividerHeight`)
  /// — the vertical `Divider` fills it (`h-full`).
  final WebElementChrome dividerBox;

  /// Nested [CoreToggleGroupStyle] for the composed segments —
  /// `CoreFilterStyle.defaultToggleGroupStyle`, the deprecated flat
  /// track / segment fields and the per-instance slot folded in
  /// (`toggleGroupStyleFor`), raw-forwarded to
  /// `ToggleGroup(toggleGroupStyle:)`.
  final CoreToggleGroupStyle toggleGroupStyle;

  /// Nested [CoreDividerStyle] of the hairline, raw-forwarded to
  /// `Divider(dividerStyle:)`.
  final CoreDividerStyle dividerStyle;

  /// Reset-affordance button style — chained design-system default +
  /// per-instance override, raw-forwarded to
  /// `Button(variant: .ghost, size: .sm, shape: .square, buttonStyle: …)`
  /// (the button emits its own colours / square / radius / transition /
  /// focus-ring; the rem unit it emits is browser-scale reactive, so no
  /// parent-side scaling).
  final CoreButtonStyle resetButtonStyle;
}

// ════════════════════════════════════════════════════════════════
// resolveFilter — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedFilter] for the given Web [context].
///
/// ```text
/// design system default → CoreFilterTheme.style
///   → CoreFilterTheme.variantStyles[variant] → component.filterStyle
/// ```
///
/// [size] picks the Filter's own size row (`CoreFilterStyle.defaultsBySize`
/// — the reset button height and the hairline length); the segments read
/// the same size through the composed `ToggleGroup`.
ResolvedFilter resolveFilter(
  BuildContext context, {
  required CoreFilterVariant variant,
  CoreComponentSize size = CoreFilterContract.defaultSize,
  CoreFilterStyle? filterStyle,
  bool enabled = true,
}) {
  final filterTheme = context.theme.coreComponentTheme?.filter;

  final merged = resolveStyleChain(const CoreFilterStyle(), [
    filterTheme?.style,
    filterTheme?.variantStyles?[variant],
    filterStyle,
  ]);

  // The size row — sits between the merged override and the flat default.
  final sizeRow = CoreFilterStyle.sizeDefaults(size);

  // Nested slots — composite `default.merge(override)`, raw-forwarded.
  final toggleGroupStyle = merged.toggleGroupStyleFor();
  // While disabled the hairline takes the disabled outline so it fades with
  // the disabled track and labels; the enabled colour stays the divider
  // slot's own.
  final dividerStyle = CoreFilterStyle.defaultDividerStyle
      .merge(merged.dividerStyle)
      .merge(
        enabled
            ? null
            : CoreDividerStyle(
                color:
                    merged.disabledDividerColor ??
                    CoreFilterStyle.defaultDisabledDividerColor,
              ),
      );
  final resetButtonStyle = CoreFilterStyle.defaultResetButtonStyle
      .merge(sizeRow.resetButtonStyle)
      .merge(merged.resetButtonStyle);

  final dividerHeight =
      merged.dividerHeight ??
      sizeRow.dividerHeight ??
      CoreFilterStyle.defaultDividerHeight;
  final trailingSpacing =
      merged.trailingSpacing ?? CoreFilterStyle.defaultTrailingSpacing;
  final dividerLeadingSpacing =
      merged.dividerLeadingSpacing ??
      CoreFilterStyle.defaultDividerLeadingSpacing;
  // The group's own gap already sits between the last segment and the
  // trailing slot; only the rest of the leading distance is added here.
  final groupItemSpacing =
      toggleGroupStyle.itemSpacing ?? CoreToggleGroupStyle.defaultItemSpacing;

  // ─── Local builders ───────────────────────────────────

  /// The trailing row — an inline flex row, centred on the cross axis.
  String buildRootClassName() => WebLayout.inlineFlexItemsCenter;

  /// The gap between the hairline and the reset button, and the room in
  /// front of the hairline (spacings, so both go through `spaceCss` and
  /// follow a density). The room is the leading distance minus the group's
  /// own gap, never negative — the same difference the Flutter resolver
  /// takes.
  Styles buildRootInlineStyles() {
    final leading = spaceCss(dividerLeadingSpacing);
    final groupGap = spaceCss(groupItemSpacing);
    // The clamp's floor, not a design value: the room never goes negative
    // when the group's gap outgrows the leading distance.
    final none = spaceCss(0);
    return .new(
      raw: {
        'gap': spaceCss(trailingSpacing),
        'padding-inline-start': 'max($none, calc($leading - $groupGap))',
      },
    );
  }

  /// The hairline's box: a fixed length the vertical divider fills. A
  /// length of the hairline itself, not a spacing, so a density leaves it.
  String buildDividerBoxClassName() =>
      [WebLayout.flex, WebLayout.shrinkZero].join(' ');

  Styles buildDividerBoxInlineStyles() =>
      .new(raw: {'height': pinnedLengthCss(dividerHeight)});

  return ResolvedFilter(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    dividerBox: WebElementChrome(
      className: buildDividerBoxClassName(),
      inlineStyles: buildDividerBoxInlineStyles(),
    ),
    toggleGroupStyle: toggleGroupStyle,
    dividerStyle: dividerStyle,
    resetButtonStyle: resetButtonStyle,
  );
}
