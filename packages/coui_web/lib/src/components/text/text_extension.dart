import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/color_scheme.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart' hide Text;

/// Tailwind opacity utility 는 0..100 정수 percent 를 받는다 — alpha
/// 0..1 을 percent 로 변환할 때 곱하는 스케일.
const _kPercentScale = 100;

/// Chain modifiers on [Text].
///
/// Spec: `docs/specs/typography-tokens.md` (CoUI Typography Token v1.1).
///
/// Primitive 와 Semantic 둘 다 chain 으로 사용 가능 — 사용자 코드는
/// 다음과 같이 자유롭게 조합:
///
/// ```dart
/// Text('hi').bodyMedium.semiBold.primary    // semantic + primitive
/// Text('hi').s14.bold.error                  // primitive only
/// Text('hi').headlineLarge.italic            // semantic + modifier
/// ```
///
/// Spec 의 `CoreFontSize.s10..s128` / `CoreFontWeight.thin..black` /
/// `CoreLineHeight.h100..h200` / `CoreLetterSpacing.tighter..widest` /
/// `CoreFontFamily.sans/serif/mono` 모두 named chain 으로 노출.
extension TextExtension on Text {
  /// Composes a build-time builder onto the existing [Text.styleBuilder].
  ///
  /// 토큰 chain (ColorScheme `cs.primary` 등) 은 build 시점에
  /// resolve 되어야 Theme override 자동 반영 — Flutter `WrappedText.
  /// style: (context, theme) => ...` 패턴 미러.
  Text _withBuilder(TextStyleBuilder builder) {
    final existing = styleBuilder;
    final TextStyleBuilder merged;
    if (existing == null) {
      merged = builder;
    } else {
      merged = (ctx) => existing(ctx).merge(builder(ctx));
    }
    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: style,
        styleBuilder: merged,
        softWrap: softWrap,
        overflow: overflow,
        maxLines: maxLines,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        semanticsLabel: semanticsLabel,
        textScaler: textScaler,
      );
    }
    return Text(
      data,
      style: style,
      styleBuilder: merged,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      semanticsLabel: semanticsLabel,
      textScaler: textScaler,
    );
  }

  /// Replaces [Text.styleBuilder] outright — for a chain step that must
  /// clear fields set before it, which a merge cannot do.
  Text _replaceBuilder(TextStyleBuilder builder) {
    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: style,
        styleBuilder: builder,
        softWrap: softWrap,
        overflow: overflow,
        maxLines: maxLines,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        semanticsLabel: semanticsLabel,
        textScaler: textScaler,
      );
    }
    return Text(
      data,
      style: style,
      styleBuilder: builder,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      semanticsLabel: semanticsLabel,
      textScaler: textScaler,
    );
  }

  /// Convenience for static chains that don't need [BuildContext].
  Text _withStyle(TextStyle merged) => _withBuilder((_) => merged);

  /// Helper for ColorScheme token chains — build-time resolved.
  ///
  /// Each `cs.<token>` callsite below returns a [CoreColor?] (the
  /// semantic scheme field). [CoreColor.toString] renders the Tailwind
  /// class suffix (e.g. `'primary'`, `'on-surface'`); raw / unknown
  /// colours leave `TextStyle.color` absent (no `text-*` class emitted).
  Text _withColor(CoreColor? Function(ColorScheme cs) resolve) => _withBuilder(
    (ctx) => TextStyle(
      color: resolve(ctx.theme.colorScheme)?.toString(),
    ),
  );

  // Sets the role only — no fontSize/fontWeight/letterSpacing/height
  // literal. `Text.build()` emits this as the single `text-${role}` class,
  // which already carries all four via CSS variables
  // (`ThemeConfig._semanticFontSizeConfig`), so the role stays reactive to
  // runtime theme/surface-style overrides instead of freezing today's
  // `CoreTypography.coui` values into the DOM.
  //
  // The role REPLACES the size, weight, line height and family chained
  // before it (`TextStyle.withRole`), as Flutter's role getter does — left
  // in place they emit inline / as a `font-*` class and beat the role
  // class, so `.s20.codeSm` drew 20px here and 12px in Flutter.
  Text _withCoreTextStyle(CoreTextStyleToken token) {
    final existing = styleBuilder;
    if (existing == null) return _withStyle(TextStyle(role: token.name));
    return _replaceBuilder((ctx) => existing(ctx).withRole(token.name));
  }

  // ── Semantic typography (22) — coui_core token re-use ──

  /// The `displayLarge` typography role.
  Text get displayLarge => _withCoreTextStyle(CoreTextStyles.displayLarge);

  /// The `displayMedium` typography role.
  Text get displayMedium => _withCoreTextStyle(CoreTextStyles.displayMedium);

  /// The `displaySmall` typography role.
  Text get displaySmall => _withCoreTextStyle(CoreTextStyles.displaySmall);

  /// The `headlineLarge` typography role.
  Text get headlineLarge => _withCoreTextStyle(CoreTextStyles.headlineLarge);

  /// The `headlineMedium` typography role.
  Text get headlineMedium => _withCoreTextStyle(CoreTextStyles.headlineMedium);

  /// The `headlineSmall` typography role.
  Text get headlineSmall => _withCoreTextStyle(CoreTextStyles.headlineSmall);

  /// The `titleLarge` typography role.
  Text get titleLarge => _withCoreTextStyle(CoreTextStyles.titleLarge);

  /// The `titleMedium` typography role.
  Text get titleMedium => _withCoreTextStyle(CoreTextStyles.titleMedium);

  /// The `titleSmall` typography role.
  Text get titleSmall => _withCoreTextStyle(CoreTextStyles.titleSmall);

  /// The `bodyLarge` typography role.
  Text get bodyLarge => _withCoreTextStyle(CoreTextStyles.bodyLarge);

  /// The `bodyMedium` typography role.
  Text get bodyMedium => _withCoreTextStyle(CoreTextStyles.bodyMedium);

  /// The `bodySmall` typography role.
  Text get bodySmall => _withCoreTextStyle(CoreTextStyles.bodySmall);

  /// The `bodyXs` typography role — helper text, metadata.
  Text get bodyXs => _withCoreTextStyle(CoreTextStyles.bodyXs);

  /// The `labelXl2` typography role — the largest control-label rung.
  Text get labelXl2 => _withCoreTextStyle(CoreTextStyles.labelXl2);

  /// The `labelXl` typography role.
  Text get labelXl => _withCoreTextStyle(CoreTextStyles.labelXl);

  /// The `labelLarge` typography role.
  Text get labelLarge => _withCoreTextStyle(CoreTextStyles.labelLarge);

  /// The `labelMedium` typography role.
  Text get labelMedium => _withCoreTextStyle(CoreTextStyles.labelMedium);

  /// The `labelSmall` typography role.
  Text get labelSmall => _withCoreTextStyle(CoreTextStyles.labelSmall);

  /// The `labelXs` typography role — the smallest label.
  Text get labelXs => _withCoreTextStyle(CoreTextStyles.labelXs);

  // The code roles also name their own face. That rides a `:where()` rule
  // on the role class (`ThemeConfig.typographyCssBlock`), so the chain
  // still sets only the role and an explicit `.sans` / `.mono` after it
  // wins.

  /// The `codeXs` typography role — mono on the shared code line box.
  Text get codeXs => _withCoreTextStyle(CoreTextStyles.codeXs);

  /// The `codeSm` typography role — mono on the shared code line box.
  Text get codeSm => _withCoreTextStyle(CoreTextStyles.codeSm);

  /// The `codeMd` typography role — mono on the shared code line box.
  Text get codeMd => _withCoreTextStyle(CoreTextStyles.codeMd);

  // ── Font size primitive (21) — CoreFontSize.s* 1:1 ──

  /// Font size `CoreFontSize.s10`.
  Text get s10 => _withStyle(const TextStyle(fontSize: CoreFontSize.s10));

  /// Font size `CoreFontSize.s11`.
  Text get s11 => _withStyle(const TextStyle(fontSize: CoreFontSize.s11));

  /// Font size `CoreFontSize.s12`.
  Text get s12 => _withStyle(const TextStyle(fontSize: CoreFontSize.s12));

  /// Font size `CoreFontSize.s13`.
  Text get s13 => _withStyle(const TextStyle(fontSize: CoreFontSize.s13));

  /// Font size `CoreFontSize.s14`.
  Text get s14 => _withStyle(const TextStyle(fontSize: CoreFontSize.s14));

  /// Font size `CoreFontSize.s15`.
  Text get s15 => _withStyle(const TextStyle(fontSize: CoreFontSize.s15));

  /// Font size `CoreFontSize.s16`.
  Text get s16 => _withStyle(const TextStyle(fontSize: CoreFontSize.s16));

  /// Font size `CoreFontSize.s18`.
  Text get s18 => _withStyle(const TextStyle(fontSize: CoreFontSize.s18));

  /// Font size `CoreFontSize.s20`.
  Text get s20 => _withStyle(const TextStyle(fontSize: CoreFontSize.s20));

  /// Font size `CoreFontSize.s24`.
  Text get s24 => _withStyle(const TextStyle(fontSize: CoreFontSize.s24));

  /// Font size `CoreFontSize.s28`.
  Text get s28 => _withStyle(const TextStyle(fontSize: CoreFontSize.s28));

  /// Font size `CoreFontSize.s32`.
  Text get s32 => _withStyle(const TextStyle(fontSize: CoreFontSize.s32));

  /// Font size `CoreFontSize.s36`.
  Text get s36 => _withStyle(const TextStyle(fontSize: CoreFontSize.s36));

  /// Font size `CoreFontSize.s40`.
  Text get s40 => _withStyle(const TextStyle(fontSize: CoreFontSize.s40));

  /// Font size `CoreFontSize.s44`.
  Text get s44 => _withStyle(const TextStyle(fontSize: CoreFontSize.s44));

  /// Font size `CoreFontSize.s48`.
  Text get s48 => _withStyle(const TextStyle(fontSize: CoreFontSize.s48));

  /// Font size `CoreFontSize.s52`.
  Text get s52 => _withStyle(const TextStyle(fontSize: CoreFontSize.s52));

  /// Font size `CoreFontSize.s60`.
  Text get s60 => _withStyle(const TextStyle(fontSize: CoreFontSize.s60));

  /// Font size `CoreFontSize.s72`.
  Text get s72 => _withStyle(const TextStyle(fontSize: CoreFontSize.s72));

  /// Font size `CoreFontSize.s96`.
  Text get s96 => _withStyle(const TextStyle(fontSize: CoreFontSize.s96));

  /// Font size `CoreFontSize.s128`.
  Text get s128 => _withStyle(const TextStyle(fontSize: CoreFontSize.s128));

  // ── Font weight primitive (9) ──

  /// Font weight `CoreFontWeight.thin`.
  Text get thin => _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.thin));

  /// Font weight `CoreFontWeight.extraLight`.
  Text get extraLight =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.extralight));

  /// Font weight `CoreFontWeight.light`.
  Text get light =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.light));

  /// Font weight `CoreFontWeight.regular`.
  Text get regular =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.regular));

  /// Font weight `CoreFontWeight.medium`.
  Text get medium =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.medium));

  /// Font weight `CoreFontWeight.semiBold`.
  Text get semiBold =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.semibold));

  /// Font weight `CoreFontWeight.bold`.
  Text get bold => _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.bold));

  /// Font weight `CoreFontWeight.extraBold`.
  Text get extraBold =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.extrabold));

  /// Font weight `CoreFontWeight.black`.
  Text get black =>
      _withStyle(TextStyle(fontWeight: CoreFontWeight.scale.black));

  // ── Line height primitive (7) ──

  /// Line height `CoreLineHeight.h100`.
  Text get h100 => _withStyle(const TextStyle(height: CoreLineHeight.h100));

  /// Line height `CoreLineHeight.h120`.
  Text get h120 => _withStyle(const TextStyle(height: CoreLineHeight.h120));

  /// Line height `CoreLineHeight.h140`.
  Text get h140 => _withStyle(const TextStyle(height: CoreLineHeight.h140));

  /// Line height `CoreLineHeight.h150`.
  Text get h150 => _withStyle(const TextStyle(height: CoreLineHeight.h150));

  /// Line height `CoreLineHeight.h160`.
  Text get h160 => _withStyle(const TextStyle(height: CoreLineHeight.h160));

  /// Line height `CoreLineHeight.h180`.
  Text get h180 => _withStyle(const TextStyle(height: CoreLineHeight.h180));

  /// Line height `CoreLineHeight.h200`.
  Text get h200 => _withStyle(const TextStyle(height: CoreLineHeight.h200));

  // ── Letter spacing primitive (6) ──

  /// Letter spacing `CoreLetterSpacing.tighter`.
  Text get tighter =>
      _withStyle(const TextStyle(letterSpacing: CoreLetterSpacing.tighter));

  /// Letter spacing `CoreLetterSpacing.tight`.
  Text get tight =>
      _withStyle(const TextStyle(letterSpacing: CoreLetterSpacing.tight));

  /// Letter spacing `CoreLetterSpacing.normal` — named apart from the
  /// `normal` weight it would otherwise shadow.
  Text get normalSpacing =>
      _withStyle(const TextStyle(letterSpacing: CoreLetterSpacing.normal));

  /// Letter spacing `CoreLetterSpacing.wide`.
  Text get wide =>
      _withStyle(const TextStyle(letterSpacing: CoreLetterSpacing.wide));

  /// Letter spacing `CoreLetterSpacing.wider`.
  Text get wider =>
      _withStyle(const TextStyle(letterSpacing: CoreLetterSpacing.wider));

  /// Letter spacing `CoreLetterSpacing.widest`.
  Text get widest =>
      _withStyle(const TextStyle(letterSpacing: CoreLetterSpacing.widest));

  // ── Font family primitive (3) ──

  /// `font-sans` (Pretendard).
  Text get sans => _withStyle(TextStyle(fontFamily: CoreFontFamily.scale.sans));

  /// `font-serif` (TBD — 미정).
  Text get serif =>
      _withStyle(TextStyle(fontFamily: CoreFontFamily.scale.serif));

  /// `font-mono` (Geist Mono, with Pretendard for Hangul).
  Text get mono => _withStyle(TextStyle(fontFamily: CoreFontFamily.scale.mono));

  // ── Style modifiers ──

  /// Italic text.
  Text get italic => _withStyle(const TextStyle(fontStyle: .italic));

  /// Underlines the text in its own colour.
  Text get underline => _withStyle(const TextStyle(decoration: .underline));

  /// Strikes the text through in its own colour.
  Text get lineThrough => _withStyle(const TextStyle(decoration: .lineThrough));

  /// Draws a line above the text in its own colour.
  Text get overline => _withStyle(const TextStyle(decoration: .overline));

  // ── ColorScheme tokens (44) — build-time resolved from `cs.<token>` ──
  //
  // 44 rather than one-per-slot: `warning` is withheld. See the Warning
  // block for why that one slot cannot be a text colour.

  // Surface (8)
  /// Colours the text with the colour scheme's `surface` role.
  Text get surface => _withColor((cs) => cs.surface);

  /// Colours the text with the colour scheme's `surfaceDim` role.
  Text get surfaceDim => _withColor((cs) => cs.surfaceDim);

  /// Colours the text with the colour scheme's `surfaceBright` role.
  Text get surfaceBright => _withColor((cs) => cs.surfaceBright);

  /// Colours the text with the colour scheme's `surfaceContainerLowest` role.
  Text get surfaceContainerLowest =>
      _withColor((cs) => cs.surfaceContainerLowest);

  /// Colours the text with the colour scheme's `surfaceContainerLow` role.
  Text get surfaceContainerLow => _withColor((cs) => cs.surfaceContainerLow);

  /// Colours the text with the colour scheme's `surfaceContainer` role.
  Text get surfaceContainer => _withColor((cs) => cs.surfaceContainer);

  /// Colours the text with the colour scheme's `surfaceContainerHigh` role.
  Text get surfaceContainerHigh => _withColor((cs) => cs.surfaceContainerHigh);

  /// Colours the text with the colour scheme's `surfaceContainerHighest` role.
  Text get surfaceContainerHighest =>
      _withColor((cs) => cs.surfaceContainerHighest);

  // On surface (2) + tint
  /// Colours the text with the colour scheme's `onSurface` role.
  Text get onSurface => _withColor((cs) => cs.onSurface);

  /// Colours the text with the colour scheme's `onSurfaceVariant` role.
  Text get onSurfaceVariant => _withColor((cs) => cs.onSurfaceVariant);

  /// Colours the text with the colour scheme's `surfaceTint` role.
  Text get surfaceTint => _withColor((cs) => cs.surfaceTint);

  // Accent fills are absent as text colours, and that absence is the point.
  //
  // `check_contrast.dart` audits every accent as page text against WCAG
  // 1.4.3's 4.5:1. They cleared it — but only just, 4.63:1 to 7.04:1, and
  // that file says why it kept measuring them: the margin is thin enough
  // that a palette nudge would cross it. An affordance one brand-colour
  // adjustment away from unreadable is not one to keep offering.
  //
  // The tone accent-hued text actually wants already exists and is already
  // what the examples reach for: `onXContainer`. Warning went first, for a
  // stronger reason (1.82:1, structurally unfixable); the other six follow
  // for this one.
  //
  // `check_accent_text_contrast.sh` keeps them from coming back, because a
  // re-added getter would fail no test — it would just render text at a
  // ratio nobody re-measured.

  // Primary (3)
  /// Colours the text with the colour scheme's `onPrimary` role.
  Text get onPrimary => _withColor((cs) => cs.onPrimary);

  /// Colours the text with the colour scheme's `primaryContainer` role.
  Text get primaryContainer => _withColor((cs) => cs.primaryContainer);

  /// Colours the text with the colour scheme's `onPrimaryContainer` role.
  Text get onPrimaryContainer => _withColor((cs) => cs.onPrimaryContainer);

  // Secondary (3)
  /// Colours the text with the colour scheme's `onSecondary` role.
  Text get onSecondary => _withColor((cs) => cs.onSecondary);

  /// Colours the text with the colour scheme's `secondaryContainer` role.
  Text get secondaryContainer => _withColor((cs) => cs.secondaryContainer);

  /// Colours the text with the colour scheme's `onSecondaryContainer` role.
  Text get onSecondaryContainer => _withColor((cs) => cs.onSecondaryContainer);

  // Tertiary (3)
  /// Colours the text with the colour scheme's `onTertiary` role.
  Text get onTertiary => _withColor((cs) => cs.onTertiary);

  /// Colours the text with the colour scheme's `tertiaryContainer` role.
  Text get tertiaryContainer => _withColor((cs) => cs.tertiaryContainer);

  /// Colours the text with the colour scheme's `onTertiaryContainer` role.
  Text get onTertiaryContainer => _withColor((cs) => cs.onTertiaryContainer);

  // Error (3)
  /// Colours the text with the colour scheme's `onError` role.
  Text get onError => _withColor((cs) => cs.onError);

  /// Colours the text with the colour scheme's `errorContainer` role.
  Text get errorContainer => _withColor((cs) => cs.errorContainer);

  /// Colours the text with the colour scheme's `onErrorContainer` role.
  Text get onErrorContainer => _withColor((cs) => cs.onErrorContainer);

  // Success (3)
  /// Colours the text with the colour scheme's `onSuccess` role.
  Text get onSuccess => _withColor((cs) => cs.onSuccess);

  /// Colours the text with the colour scheme's `successContainer` role.
  Text get successContainer => _withColor((cs) => cs.successContainer);

  /// Colours the text with the colour scheme's `onSuccessContainer` role.
  Text get onSuccessContainer => _withColor((cs) => cs.onSuccessContainer);

  // Warning (3) — its fill was never offered here. Unlike the six above it
  // is not a thin margin but an impossible one: 1.82:1, because `warning`
  // is the one role whose `onWarning` is black, which is to say its fill is
  // light by design. Darkening it to read as text breaks that foreground.
  /// Colours the text with the colour scheme's `onWarning` role.
  Text get onWarning => _withColor((cs) => cs.onWarning);

  /// Colours the text with the colour scheme's `warningContainer` role.
  Text get warningContainer => _withColor((cs) => cs.warningContainer);

  /// Colours the text with the colour scheme's `onWarningContainer` role.
  Text get onWarningContainer => _withColor((cs) => cs.onWarningContainer);

  // Info (3)
  /// Colours the text with the colour scheme's `onInfo` role.
  Text get onInfo => _withColor((cs) => cs.onInfo);

  /// Colours the text with the colour scheme's `infoContainer` role.
  Text get infoContainer => _withColor((cs) => cs.infoContainer);

  /// Colours the text with the colour scheme's `onInfoContainer` role.
  Text get onInfoContainer => _withColor((cs) => cs.onInfoContainer);

  // Outline (2)
  /// Colours the text with the colour scheme's `outline` role.
  Text get outline => _withColor((cs) => cs.outline);

  /// Colours the text with the colour scheme's `outlineVariant` role.
  Text get outlineVariant => _withColor((cs) => cs.outlineVariant);

  // Inverse (3)
  /// Colours the text with the colour scheme's `inverseSurface` role.
  Text get inverseSurface => _withColor((cs) => cs.inverseSurface);

  /// Colours the text with the colour scheme's `inverseOnSurface` role.
  Text get inverseOnSurface => _withColor((cs) => cs.inverseOnSurface);

  /// Colours the text with the colour scheme's `inversePrimary` role.
  Text get inversePrimary => _withColor((cs) => cs.inversePrimary);

  // Misc (2)
  /// Colours the text with the colour scheme's `shadow` role.
  Text get shadow => _withColor((cs) => cs.shadow);

  /// Colours the text with the colour scheme's `scrim` role.
  Text get scrim => _withColor((cs) => cs.scrim);

  // ── Convenience aliases (호환) ──

  /// Alias for [onPrimary].
  Text get primaryForeground => onPrimary;

  /// Alias for [onSecondary].
  Text get secondaryForeground => onSecondary;

  // Layout / wrap props (`maxLines` / `overflow` / `textAlign` /
  // `softWrap` / `textDirection` / `locale` / `semanticsLabel` /
  // `textScaler`) 는 named param 으로만 사용. instance field 와 같은
  // 이름의 chain 메서드는 Dart 룰상 호출 불가 (field 우선) — 양쪽
  // 플랫폼 동일 한계라 named param 통일이 근본적으로 맞다.

  /// Multiplies the foreground colour alpha by [value] (`0..1`). Mirrors
  /// Flutter `Text.opacity(value)`.
  ///
  /// 직전 chain 이 explicit color 를 set 했다면 그 색의 alpha 를 스케일,
  /// 없으면 inherited `onSurface` 토큰 위에 alpha 를 적용한다. Tailwind
  /// `text-{color}/{percent}` 유틸리티로 emit (예: `.primary.opacity(0.5)`
  /// → `text-primary/50`).
  Text opacity(double value) => _withBuilder((ctx) {
    final cs = ctx.theme.colorScheme;
    // 누적된 chain (이 builder 가 호출되는 시점에 이전 builder 결과가
    // 합쳐진 상태) 를 다시 읽어오기 어려우니, 현재 styleBuilder 를 호출해
    // 누적된 color 를 추출. 없으면 onSurface fallback.
    final upstream = styleBuilder?.call(ctx);
    final upstreamColor = upstream?.color ?? style?.color ?? cs.onSurface;
    final pct = (value.clamp(0, 1) * _kPercentScale).round();
    return TextStyle(color: '$upstreamColor/$pct');
  });

  // ── Direct prop chain (parity with Flutter `Widget` extension) ──
  // raw value 를 직접 받는 chain. Tailwind token 이 아닌 임의 값을 쓸
  // 때 사용 (예: `Text('hi').fontSize(20)`).

  /// Sets the explicit font size (logical pixels). Mirrors Flutter
  /// `Text.fontSize(value)`.
  Text fontSize(double value) => _withStyle(TextStyle(fontSize: value));

  /// Sets the font weight (`100..900`, matching `CoreFontWeight.semiBold`
  /// / `CoreFontWeight.medium` / etc). Mirrors Flutter `Text.fontWeight(value)`.
  Text fontWeight(int value) =>
      _withStyle(TextStyle(fontWeight: _fontWeightToken(value)));

  /// Sets the explicit line-height multiplier. Mirrors Flutter
  /// `Text.lineHeight(value)`.
  Text lineHeight(double value) => _withStyle(TextStyle(height: value));

  /// Sets the letter spacing in `em`. Mirrors Flutter
  /// `Text.letterSpacing(value)`.
  Text letterSpacing(double value) =>
      _withStyle(TextStyle(letterSpacing: value));

  /// Sets the text decoration. Mirrors Flutter
  /// `Text.decoration(value)`.
  Text decoration(CoreTextDecoration value) =>
      _withStyle(TextStyle(decoration: value));

  // ── Layout / wrap chain (SwiftUI-style, non-field names) ──
  //
  // The `maxLines` / `overflow` *fields* would shadow same-named chain
  // methods (Dart resolves an instance member over an extension member),
  // so these use non-clashing names — `lineLimit` (SwiftUI) and the four
  // overflow getters — which have no field to shadow them and are
  // therefore reachable directly on a bare `Text`. Flutter mirrors these
  // 1:1 on `TextExtension on Widget`.

  /// Returns a copy of this [Text] with [maxLines] / [overflow] replaced,
  /// preserving the text (or [Text.rich] span), any accumulated
  /// [Text.style] / [Text.styleBuilder], and every other layout prop.
  /// The Web `Text` has no `copyWith`, so — mirroring [_withBuilder] —
  /// chain modifiers rebuild it via the constructor carrying its fields.
  Text _withLayout({int? maxLines, CoreTextOverflow? overflow}) {
    final nextMaxLines = maxLines ?? this.maxLines;
    final nextOverflow = overflow ?? this.overflow;
    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: style,
        styleBuilder: styleBuilder,
        softWrap: softWrap,
        overflow: nextOverflow,
        maxLines: nextMaxLines,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        semanticsLabel: semanticsLabel,
        textScaler: textScaler,
      );
    }
    return Text(
      data,
      style: style,
      styleBuilder: styleBuilder,
      softWrap: softWrap,
      overflow: nextOverflow,
      maxLines: nextMaxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      semanticsLabel: semanticsLabel,
      textScaler: textScaler,
    );
  }

  /// Clamps the text to at most [maxLines] lines. Named after SwiftUI's
  /// `.lineLimit(_)`; a non-field name so it is reachable directly on a
  /// bare `Text`. Mirrors Flutter `Text('...').lineLimit(n)`.
  Text lineLimit(int maxLines) => _withLayout(maxLines: maxLines);

  /// Truncates overflowing text with an ellipsis (`…`)
  /// (`CoreTextOverflow.ellipsis`). Mirrors Flutter `Text('...').ellipsis`.
  Text get ellipsis => _withLayout(overflow: .ellipsis);

  // NOTE — there is intentionally no clip overflow getter here. It is kept
  // identical to the Flutter side, where a clip getter would collide with
  // the existing layout clip extension on Widget and raise an ambiguous
  // extension member access. Pass the clip overflow through the Text
  // widget's overflow named parameter directly when an explicit clip is
  // needed.

  /// Fades overflowing text out (`CoreTextOverflow.fade`). Mirrors
  /// Flutter `Text('...').fade`.
  Text get fade => _withLayout(overflow: .fade);

  /// Renders overflowing text outside its bounds without clipping
  /// (`CoreTextOverflow.visible`). Mirrors Flutter `Text('...').visible`.
  Text get visible => _withLayout(overflow: .visible);

  /// Breaks lines between words only — CSS `word-break: keep-all`, the
  /// convention for Korean. A word wider than the line still breaks
  /// inside (`overflow-wrap: anywhere`). The string is left as it is.
  /// Mirrors Flutter `Text('...').keepAll`, which draws the same lines
  /// from `CoreKeepAll`.
  Text get keepAll => _withStyle(const TextStyle(wordBreakKeepAll: true));
}

/// Maps `CoreFontWeight` int (100..900) → Tailwind weight token name.
String _fontWeightToken(int weight) {
  return switch (weight) {
    CoreFontWeight.thin => CoreFontWeight.scale.thin,
    CoreFontWeight.extraLight => CoreFontWeight.scale.extralight,
    CoreFontWeight.light => CoreFontWeight.scale.light,
    CoreFontWeight.medium => CoreFontWeight.scale.medium,
    CoreFontWeight.semiBold => CoreFontWeight.scale.semibold,
    CoreFontWeight.bold => CoreFontWeight.scale.bold,
    CoreFontWeight.extraBold => CoreFontWeight.scale.extrabold,
    CoreFontWeight.black => CoreFontWeight.scale.black,
    _ => CoreFontWeight.scale.regular,
  };
}
