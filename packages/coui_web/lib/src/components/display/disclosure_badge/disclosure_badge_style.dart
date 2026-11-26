import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `DisclosureBadge`.
///
/// DOM shape:
///
/// ```text
/// root (<span>)                   // outline + label colour + typography
///   ├─ marker (<span>)            // co_disclosure_badge renders this only
///   │                             // when kind.hasMarker
///   └─ label text
/// ```
///
/// `disclosure_badge.dart` reads `className` / `inlineStyles` straight
/// off these slots — no merge / fallback / conversion in the widget body.
///
/// [marker] is always built (non-null); the widget decides whether to
/// render it from [CoreDisclosureKind.hasMarker], which keeps the
/// shape decision on the enum rather than in resolved output.
class ResolvedDisclosureBadge implements WebResolvedChrome {
  /// Creates a [ResolvedDisclosureBadge].
  const ResolvedDisclosureBadge({required this.root, required this.marker});

  /// Paint-ready chrome for the outermost `<span>`.
  ///
  /// Carries the outline (width / pattern / colour), the label colour
  /// and typography role, the corner radius and the padding. It carries
  /// **no** background: a disclosure badge is deliberately unfilled so
  /// it does not read as a pressable control.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the deferral marker dot.
  ///
  /// Rendered only for [CoreDisclosureKind.commitment]. Filled with the
  /// same colour the label uses, so a single `foregroundColor` override
  /// keeps the dot and the word in step.
  final WebElementChrome marker;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDisclosureBadge] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default for kind
///   → theme.coreComponentTheme.disclosureBadge.style
///   → theme.coreComponentTheme.disclosureBadge.kindStyles[kind]
///   → widget.disclosureBadgeStyle
/// ```
///
/// The semantic [kind] is a widget prop — it threads through to pick the
/// per-kind colour table and the stroke / marker shape here, and the
/// theme cannot override it.
///
/// ### Class-vs-inline
///
/// Every default lands on a Tailwind class — colour through [emitColor],
/// typography through [emitTypography], radius through [emitRadius],
/// padding through [emitSpacing], the stroke pattern through
/// `border-solid` / `border-dashed`. A stylesheet can therefore beat any
/// of them. Only a caller's explicit override moves inline, which is the
/// one case where winning on specificity is the point.
///
/// The single exception is the border **width**, which has no Tailwind
/// emitter in this repo and rides `strokeWidthCss` inline. That still
/// resolves through the `--coui-stroke-width-N` variable, so a designer
/// override of that variable reaches this component the same way it
/// reaches `Divider` and `Badge` — the value is not frozen at a literal.
ResolvedDisclosureBadge resolveDisclosureBadge(
  BuildContext context, {
  required CoreDisclosureKind kind,
  CoreDisclosureBadgeStyle? disclosureBadgeStyle,
}) {
  final badgeTheme = context.theme.coreComponentTheme?.disclosureBadge;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDisclosureBadgeStyle(), [
    badgeTheme?.style,
    badgeTheme?.kindStyles?[kind],
    disclosureBadgeStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final kindStyle = CoreDisclosureBadgeStyle.defaultsByKind[kind]!;

  // ─── Resolved chrome values ───────────────────────────
  final borderWidth =
      merged.borderWidth ?? CoreDisclosureBadgeStyle.defaultBorderWidth;
  final markerSize =
      merged.markerSize ?? CoreDisclosureBadgeStyle.defaultMarkerSize;
  final markerSpacing =
      merged.markerSpacing ?? CoreDisclosureBadgeStyle.defaultMarkerSpacing;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Token-bound values (per-kind defaults AND token overrides) emit
  // Tailwind classes so they stay dark-mode reactive; raw overrides go
  // inline. No `scheme.resolve` (a no-op on Web).
  final foregroundEmit = emitColor(
    merged.foregroundColor,
    kindStyle.foreground,
    .text,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    kindStyle.borderColor,
    .border,
  );
  // The dot is painted, not written, so its colour is a background fill
  // — the same resolved foreground routed to the other CSS property.
  final markerFillEmit = emitColor(
    merged.foregroundColor,
    kindStyle.foreground,
    .background,
  );
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreDisclosureBadgeStyle.defaultLabelStyle,
  );
  // An explicit nested label color wins over the shared foreground. The
  // independently emitted marker fill still reads the shared foreground.
  final labelOverridesColor = merged.labelStyle?.color != null;
  // ⚠️ `emitRadius` · `emitSpacing` 을 쓰지 않는다. 그 헬퍼들은 토큰 기본값을
  //    **class** 로 내고 오버라이드만 inline 으로 내는데, RULE F
  //    (`scripts/guards/resolver/check_web_resolver.sh`)는 chrome 을
  //    **항상 inline** 으로 요구한다. 규칙대로 직접 계산한다.
  final borderRadius =
      (merged.borderRadius ?? CoreDisclosureBadgeStyle.defaultBorderRadius)
          .toValue();
  final padding = (merged.padding ?? CoreDisclosureBadgeStyle.defaultPadding)
      .toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<span>` Tailwind className.
  ///
  /// Note what is absent and why:
  ///
  /// * no `bg-*` — the badge is unfilled (see [ResolvedDisclosureBadge.root]);
  /// * no `hover:` / `active:` / `focus:` and no `transition-*` /
  ///   `cursor-pointer` — a static marker that reacts to a pointer is
  ///   claiming to be a control;
  /// * no `select-none` — the status text is information a reader may
  ///   legitimately want to copy out of the page.
  String buildRootClassName() {
    final classList = [
      // `align-middle` keeps the badge on the text baseline when it sits
      // inline in a sentence, which is where a disclosure marker usually
      // lives (next to the row it qualifies).
      WebLayout.inlineFlexItemsCenter,
      WebLayout.whitespaceNowrap,
      'align-middle',
      // Shape — the WCAG 1.4.1 carrier. Read off the kind, never off a
      // style slot, so no theme can flatten the three states into colour.
      'border',
      switch (kind.stroke) {
        .solid => 'border-solid',
        .dashed => 'border-dashed',
      },
      labelEmit.className,
      if (!labelOverridesColor) foregroundEmit.className,
      borderEmit.className,
      // ⚠️ RULE F (`scripts/guards/resolver/check_web_resolver.sh`) —
      //    chrome(radius/padding/gap/size)은 **inline 전용**이다.
      //    `radiusEmit.className` · `paddingEmit.className` 을 여기 넣으면
      //    가드가 막는다. 두 값은 아래 inline 번들이 낸다.
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the root `<span>` inline-CSS bundle — the border width
  /// plus whatever the emit family could not put on a class (raw colour
  /// overrides, scalar typography overlays, caller-supplied radius /
  /// padding).
  Styles buildRootInlineStyles() {
    return Styles(
      raw: {
        // Stroke width — `var(--coui-stroke-width-N)`, so a designer's
        // variable override still reaches it (see the resolver doc).
        'border-width': strokeWidthCss(borderWidth),
        if (!labelOverridesColor) ...?foregroundEmit.inline,
        ...?borderEmit.inline,
        ...?labelEmit.inline,
        'border-radius': borderRadius,
        'padding': padding,
        // 마커와 라벨 사이 간격도 chrome 이라 inline 이다 (RULE F).
        if (kind.hasMarker) 'gap': spaceCss(markerSpacing),
      },
    );
  }

  /// Composes the marker dot's className — a fixed-size circle that
  /// never shrinks, so a long label cannot squeeze the shape signal out
  /// of existence.
  String buildMarkerClassName() {
    // ⚠️ RULE F — 크기·모서리는 chrome 이라 class 로 내지 않는다.
    //    `w-*` · `h-*` · `rounded-*` 는 아래 inline 번들이 낸다.
    final classList = [WebLayout.shrinkZero, markerFillEmit.className];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// 마커의 paint-ready chrome — 지름과 완전한 원.
  ///
  /// 라벨이 길어져도 형태 신호가 눌리지 않도록 크기를 고정한다.
  Styles buildMarkerInlineStyles() {
    final diameter = '${markerSize / kRemDivisor}rem';
    return Styles(
      raw: {
        'width': diameter,
        'height': diameter,
        'border-radius':
            (merged.markerRadius ??
                    CoreDisclosureBadgeStyle.defaultMarkerRadius)
                .toValue(),
        ...?markerFillEmit.inline,
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDisclosureBadge(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    marker: WebElementChrome(
      className: buildMarkerClassName(),
      inlineStyles: buildMarkerInlineStyles(),
    ),
  );
}
