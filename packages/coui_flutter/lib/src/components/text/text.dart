import 'package:coui_flutter/coui_flutter.dart' hide SelectableText;
import 'package:coui_flutter/src/components/text/keep_all_text.dart';
import 'package:flutter/gestures.dart' show GestureRecognizer;
import 'package:flutter/material.dart' show SelectableText;

/// The widget a Text chain returns.
///
/// Calling it layers raw `TextStyle` properties onto the chain — the escape
/// hatch for a value no chain getter names.
abstract class TextModifier extends Widget {
  /// Creates a [TextModifier].
  const TextModifier({super.key});

  /// Layers the given `TextStyle` properties onto the chain.
  Widget call({
    Paint? background,
    Color? backgroundColor,
    Color? color,
    String? debugLabel,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    List<FontFeature>? fontFeatures,
    double? fontSize,
    FontStyle? fontStyle,
    List<FontVariation>? fontVariations,
    FontWeight? fontWeight,
    Paint? foreground,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    double? letterSpacing,
    Locale? locale,
    TextOverflow? overflow,
    String? package,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
    double? wordSpacing,
  });
}

/// Chain modifier helper — child 가 이미 [WrappedText] 면 새 wrapper 를
/// 만들지 말고 기존 chain 위에 [style] 을 덮어쓰기 (`copyWithStyle`).
/// 그렇지 않으면 새 [WrappedText] 로 감싼다.
///
/// 트리에 wrapper 가 단일로 유지되므로 build 시 nested chain 의 inner
/// 가 outer 의 chain prop 을 덮어쓰지 않는다.
/// Chain 호출 순서상 나중에 호출된 modifier 가 우선되도록 (`copyWith` 시멘틱).
WrappedText _wrapChain(
  Widget self,
  WrappedTextDataBuilder<TextStyle> style,
) {
  return self is WrappedText
      ? self.copyWithStyle(style)
      : WrappedText(style: style, child: self);
}

/// Role chain helper — a semantic typography role (`.bodyMedium`,
/// `.titleLarge`, …) states the whole text style, so the chain is marked
/// [WrappedText.hasRole] and composes on top of CoUI's typography baseline
/// instead of the ambient `DefaultTextStyle`. Every other modifier goes
/// through [_wrapChain] and only overrides the property it names.
///
/// [role] picks the role from the active theme's typography. The role also
/// restates [WrappedText.lineHeightPx] — its fixed line box (the code
/// roles' 21px), or none for a multiplier role — so a later size modifier
/// keeps the box, and a later role replaces it.
WrappedText _wrapRole(
  Widget self,
  CoreTextStyle Function(ThemeData theme) role,
) {
  TextStyle style(BuildContext context, ThemeData theme) =>
      role(theme).toValue(theme: theme);
  double? lineHeightPx(BuildContext context, ThemeData theme) =>
      role(theme).lineHeightPx;

  return self is WrappedText
      ? self.copyWithStyle(style, role: true).copyWithLineHeightPx(lineHeightPx)
      : WrappedText(
          hasRole: true,
          lineHeightPx: lineHeightPx,
          style: style,
          child: self,
        );
}

/// Line-height chain helper — `.h140`, `.lineHeight(v)` and the like state
/// a multiplier, the newest line-height statement in the chain, so it
/// clears a fixed line box an earlier role stated
/// ([WrappedText.lineHeightPx]) the same way an overlay through
/// `CoreTextStyle.merge` does.
WrappedText _wrapLineHeight(Widget self, double height) {
  TextStyle style(BuildContext context, ThemeData theme) =>
      TextStyle(height: height);

  return self is WrappedText
      ? self.copyWithStyle(style).copyWithLineHeightPx(null)
      : WrappedText(style: style, child: self);
}

/// Letter-spacing 전용 chain helper — Flutter 의 `TextStyle.letterSpacing`
/// 은 logical pixel 이지만 Web `letter-spacing` 은 `em` (font-size 비례)
/// 단위다.
/// 두 플랫폼이 동일한 시각 결과를 내려면 chain 머지가 끝난 뒤
/// (= 최종 `fontSize` 가 결정된 뒤) `em × fontSize` 로 환산해야 한다.
///
/// 이 헬퍼는 [em] 값을 [WrappedText.letterSpacingEm] 슬롯에 누적해 build
/// 시점에 한 번만 변환되도록 한다.
/// Raw `TextStyle(letterSpacing:)` 경로와 분리되므로 `.tighter` 같은 chain
/// 이 chain 내 `.s32` 같은 fontSize 토큰과 함께 쓰여도 정확히 적용된다.
WrappedText _wrapLetterSpacingEm(Widget self, double em) {
  if (self is WrappedText) {
    return self.copyWithLetterSpacingEm((context, theme) => em);
  }
  return WrappedText(
    letterSpacingEm: (context, theme) => em,
    child: self,
  );
}

/// Max-lines chain helper — accumulates the clamp into the
/// [WrappedText.maxLines] slot (a Text-level prop, not a `TextStyle`
/// prop, so it can't route through [_wrapChain]). Later chain calls
/// override earlier ones (copyWith semantics). Mirrors
/// [_wrapLetterSpacingEm].
WrappedText _wrapMaxLines(Widget self, int maxLines) {
  if (self is WrappedText) {
    return self.copyWithMaxLines((context, theme) => maxLines);
  }
  return WrappedText(
    maxLines: (context, theme) => maxLines,
    child: self,
  );
}

/// Overflow chain helper — accumulates the resolved Flutter
/// [TextOverflow] into the [WrappedText.overflow] slot (a Text-level
/// prop, not a `TextStyle` prop, so it can't route through
/// [_wrapChain]). Later chain calls override earlier ones (copyWith
/// semantics). Mirrors [_wrapLetterSpacingEm].
WrappedText _wrapOverflow(Widget self, TextOverflow overflow) {
  if (self is WrappedText) {
    return self.copyWithOverflow((context, theme) => overflow);
  }
  return WrappedText(
    overflow: (context, theme) => overflow,
    child: self,
  );
}

/// Keep-all chain helper — sets the [WrappedText.wordBreakKeepAll] flag. Line
/// breaking is not a `TextStyle` or `DefaultTextStyle` property in
/// Flutter, so the flag cannot flow down like the other slots; the
/// wrapper redraws its child `Text` instead (see
/// [WrappedText.wordBreakKeepAll]).
WrappedText _wrapKeepAll(Widget self) {
  if (self is WrappedText) return self.copyWithKeepAll();

  return WrappedText(wordBreakKeepAll: true, child: self);
}

/// The Text chain on any widget — typography role, weight, size, colour
/// and layout modifiers, named as on the Web `Text` chain.
extension TextExtension on Widget {
  /// Sans-serif font family (Pretendard, with bundled GeistSans fallback).
  TextModifier get sans =>
      _wrapChain(this, (context, theme) => kCoreSansTextStyle);

  /// Serif font family (TBD — 미정).
  TextModifier get serif => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontFamily: CoreFontFamily.serif),
  );

  /// Monospace font family (Geist Mono — the bundled GeistMono, then
  /// Pretendard for Hangul).
  TextModifier get mono =>
      _wrapChain(this, (context, theme) => kCoreMonoTextStyle);

  /// `font-weight: 100`.
  TextModifier get thin => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.thin.weight),
  );

  /// `font-weight: 200`.
  TextModifier get extraLight => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.extraLight.weight),
  );

  /// `font-weight: 300`.
  TextModifier get light => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.light.weight),
  );

  /// `font-weight: 400` (regular). Spec 의 `regular` 와 동의어.
  TextModifier get regular => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.regular.weight),
  );

  /// `font-weight: 500`.
  TextModifier get medium => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.medium.weight),
  );

  /// `font-weight: 600`.
  TextModifier get semiBold => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.semiBold.weight),
  );

  /// `font-weight: 700`.
  TextModifier get bold => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.bold.weight),
  );

  /// `font-weight: 800`.
  TextModifier get extraBold => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.extraBold.weight),
  );

  /// `font-weight: 900`.
  TextModifier get black => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: CoreFontWeight.black.weight),
  );

  // ── Font size primitive (21) — spec 의 CoreFontSize.s* 1:1 ──

  /// 10px.
  TextModifier get s10 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s10),
  );

  /// 11px.
  TextModifier get s11 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s11),
  );

  /// 12px.
  TextModifier get s12 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s12),
  );

  /// 13px.
  TextModifier get s13 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s13),
  );

  /// 14px.
  TextModifier get s14 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s14),
  );

  /// 15px.
  TextModifier get s15 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s15),
  );

  /// 16px.
  TextModifier get s16 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s16),
  );

  /// 18px.
  TextModifier get s18 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s18),
  );

  /// 20px.
  TextModifier get s20 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s20),
  );

  /// 24px.
  TextModifier get s24 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s24),
  );

  /// 28px.
  TextModifier get s28 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s28),
  );

  /// 32px.
  TextModifier get s32 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s32),
  );

  /// 36px.
  TextModifier get s36 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s36),
  );

  /// 40px.
  TextModifier get s40 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s40),
  );

  /// 44px.
  TextModifier get s44 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s44),
  );

  /// 48px.
  TextModifier get s48 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s48),
  );

  /// 52px.
  TextModifier get s52 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s52),
  );

  /// 60px.
  TextModifier get s60 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s60),
  );

  /// 72px.
  TextModifier get s72 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s72),
  );

  /// 96px.
  TextModifier get s96 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s96),
  );

  /// 128px.
  TextModifier get s128 => _wrapChain(
    this,
    (context, theme) => const TextStyle(fontSize: CoreFontSize.s128),
  );

  // ── Line height primitive (7) — spec 의 CoreLineHeight.h* 1:1 ──
  //
  // A multiplier is the newest line-height statement, so it clears a code
  // role's fixed line box (`_wrapLineHeight`).

  /// `line-height: 1.0`.
  TextModifier get h100 => _wrapLineHeight(this, CoreLineHeight.h100);

  /// `line-height: 1.2`.
  TextModifier get h120 => _wrapLineHeight(this, CoreLineHeight.h120);

  /// `line-height: 1.4`.
  TextModifier get h140 => _wrapLineHeight(this, CoreLineHeight.h140);

  /// `line-height: 1.5` (body roles).
  TextModifier get h150 => _wrapLineHeight(this, CoreLineHeight.h150);

  /// `line-height: 1.6`.
  TextModifier get h160 => _wrapLineHeight(this, CoreLineHeight.h160);

  /// `line-height: 1.8`.
  TextModifier get h180 => _wrapLineHeight(this, CoreLineHeight.h180);

  /// `line-height: 2.0`.
  TextModifier get h200 => _wrapLineHeight(this, CoreLineHeight.h200);

  // ── Letter spacing primitive (6) — spec 의 CoreLetterSpacing.* 1:1 ──
  //
  // em 단위 토큰이므로 chain 머지가 끝난 뒤 최종 fontSize 와 곱해
  // logical pixel 로 환산된다 (`_wrapLetterSpacingEm` 참고). raw
  // `TextStyle(letterSpacing:)` 에 직접 박지 않는 이유는 Web `em` 시멘틱
  // 과 시각적 파리티를 보장하기 위함.

  /// `letter-spacing: -0.05em`.
  TextModifier get tighter =>
      _wrapLetterSpacingEm(this, CoreLetterSpacing.tighter);

  /// `letter-spacing: -0.025em`.
  TextModifier get tight => _wrapLetterSpacingEm(this, CoreLetterSpacing.tight);

  /// `letter-spacing: 0em`. `normal` (font-weight) 와 충돌 회피 위해
  /// `normalSpacing` 으로 노출.
  TextModifier get normalSpacing =>
      _wrapLetterSpacingEm(this, CoreLetterSpacing.normal);

  /// `letter-spacing: 0.025em`.
  TextModifier get wide => _wrapLetterSpacingEm(this, CoreLetterSpacing.wide);

  /// `letter-spacing: 0.05em`.
  TextModifier get wider => _wrapLetterSpacingEm(this, CoreLetterSpacing.wider);

  /// `letter-spacing: 0.1em`.
  TextModifier get widest =>
      _wrapLetterSpacingEm(this, CoreLetterSpacing.widest);

  /// Italic text.
  TextModifier get italic =>
      _wrapChain(this, (context, theme) => const TextStyle(fontStyle: .italic));

  /// Underlines the text in its own colour.
  TextModifier get underline => _wrapChain(
    this,
    // decorationColor 를 null 로 두면 Flutter 가 text color 를 자동으로
    // 따라감 (currentColor 와 동등). chain 누적 후 build 시점에 같은
    // mergedStyle 안의 `color` (예: `.error`) 가 underline 에도 적용된다.
    // 명시적으로 `DefaultTextStyle.of(context).style.color` 를 넣으면
    // ancestor 의 color (root onSurface) 만 잡혀 chain 의 color 와
    // 어긋난다.
    (context, theme) => const TextStyle(decoration: .underline),
  );

  /// Alias of [onPrimary].
  TextModifier get primaryForeground => _wrapChain(
    this,
    (context, theme) => TextStyle(
      color: theme.colorScheme.onPrimary.toValue(),
    ),
  );

  /// Alias of [onSecondary].
  TextModifier get secondaryForeground => _wrapChain(
    this,
    (context, theme) => TextStyle(
      color: theme.colorScheme.onSecondary.toValue(),
    ),
  );

  // === ColorScheme tokens (38) — build-time resolved ===
  //
  // 모든 M3 시멘틱 색상 토큰을 chain 으로 노출. Web 의 same-named
  // chain 과 1:1 대응.

  // Surface (8)
  /// Colours the text with the colour scheme's `surface` role.
  TextModifier get surface => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surface.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceDim` role.
  TextModifier get surfaceDim => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceDim.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceBright` role.
  TextModifier get surfaceBright => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceBright.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceContainerLowest` role.
  TextModifier get surfaceContainerLowest => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceContainerLowest.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceContainerLow` role.
  TextModifier get surfaceContainerLow => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceContainerLow.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceContainer` role.
  TextModifier get surfaceContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceContainerHigh` role.
  TextModifier get surfaceContainerHigh => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceContainerHigh.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceContainerHighest` role.
  TextModifier get surfaceContainerHighest => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceContainerHighest.toValue()),
  );

  // On surface (2) + tint
  /// Colours the text with the colour scheme's `onSurface` role.
  TextModifier get onSurface => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onSurface.toValue()),
  );

  /// Colours the text with the colour scheme's `onSurfaceVariant` role.
  TextModifier get onSurfaceVariant => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onSurfaceVariant.toValue()),
  );

  /// Colours the text with the colour scheme's `surfaceTint` role.
  TextModifier get surfaceTint => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.surfaceTint.toValue()),
  );

  // Primary (3)
  /// Colours the text with the colour scheme's `onPrimary` role.
  TextModifier get onPrimary => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onPrimary.toValue()),
  );

  /// Colours the text with the colour scheme's `primaryContainer` role.
  TextModifier get primaryContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.primaryContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onPrimaryContainer` role.
  TextModifier get onPrimaryContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onPrimaryContainer.toValue()),
  );

  // Secondary (3)
  /// Colours the text with the colour scheme's `onSecondary` role.
  TextModifier get onSecondary => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onSecondary.toValue()),
  );

  /// Colours the text with the colour scheme's `secondaryContainer` role.
  TextModifier get secondaryContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.secondaryContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onSecondaryContainer` role.
  TextModifier get onSecondaryContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onSecondaryContainer.toValue()),
  );

  // Tertiary (3)
  /// Colours the text with the colour scheme's `onTertiary` role.
  TextModifier get onTertiary => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onTertiary.toValue()),
  );

  /// Colours the text with the colour scheme's `tertiaryContainer` role.
  TextModifier get tertiaryContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.tertiaryContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onTertiaryContainer` role.
  TextModifier get onTertiaryContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onTertiaryContainer.toValue()),
  );

  // Error (3)
  /// Colours the text with the colour scheme's `onError` role.
  TextModifier get onError => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onError.toValue()),
  );

  /// Colours the text with the colour scheme's `errorContainer` role.
  TextModifier get errorContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.errorContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onErrorContainer` role.
  TextModifier get onErrorContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onErrorContainer.toValue()),
  );

  // Success (3)
  /// Colours the text with the colour scheme's `onSuccess` role.
  TextModifier get onSuccess => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onSuccess.toValue()),
  );

  /// Colours the text with the colour scheme's `successContainer` role.
  TextModifier get successContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.successContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onSuccessContainer` role.
  TextModifier get onSuccessContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onSuccessContainer.toValue()),
  );

  // Warning (3)
  /// Colours the text with the colour scheme's `onWarning` role.
  TextModifier get onWarning => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onWarning.toValue()),
  );

  /// Colours the text with the colour scheme's `warningContainer` role.
  TextModifier get warningContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.warningContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onWarningContainer` role.
  TextModifier get onWarningContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onWarningContainer.toValue()),
  );

  // Info (3)
  /// Colours the text with the colour scheme's `onInfo` role.
  TextModifier get onInfo => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onInfo.toValue()),
  );

  /// Colours the text with the colour scheme's `infoContainer` role.
  TextModifier get infoContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.infoContainer.toValue()),
  );

  /// Colours the text with the colour scheme's `onInfoContainer` role.
  TextModifier get onInfoContainer => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.onInfoContainer.toValue()),
  );

  // Outline (2)
  /// Colours the text with the colour scheme's `outline` role.
  TextModifier get outline => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.outline.toValue()),
  );

  /// Colours the text with the colour scheme's `outlineVariant` role.
  TextModifier get outlineVariant => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.outlineVariant.toValue()),
  );

  // Inverse (3)
  /// Colours the text with the colour scheme's `inverseSurface` role.
  TextModifier get inverseSurface => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.inverseSurface.toValue()),
  );

  /// Colours the text with the colour scheme's `inverseOnSurface` role.
  TextModifier get inverseOnSurface => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.inverseOnSurface.toValue()),
  );

  /// Colours the text with the colour scheme's `inversePrimary` role.
  TextModifier get inversePrimary => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.inversePrimary.toValue()),
  );

  // Misc (2)
  /// Colours the text with the colour scheme's `shadow` role.
  TextModifier get shadow => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.shadow.toValue()),
  );

  /// Colours the text with the colour scheme's `scrim` role.
  TextModifier get scrim => _wrapChain(
    this,
    (c, t) => TextStyle(color: t.colorScheme.scrim.toValue()),
  );

  // ── Style modifiers (line-through) ──

  /// Strikes the text through in its own colour.
  TextModifier get lineThrough => _wrapChain(
    this,
    // See `.underline` — null decorationColor 가 자동으로 text color 따라감.
    (context, theme) => const TextStyle(decoration: .lineThrough),
  );

  /// Draws a line above the text in its own colour.
  TextModifier get overline => _wrapChain(
    this,
    (context, theme) => const TextStyle(decoration: .overline),
  );

  // === Semantic Typography Modifiers (22) — CoreTextStyles 1:1 ===
  //
  // display / headline / title (3 each), body (4), label (6) and the code
  // roles (3), named as on the Web `Text` chain. Each reads the role from
  // the active theme's typography, so a theme that rescales or restyles a
  // role reaches every chain that names it.

  /// Display large semantic text style.
  TextModifier get displayLarge =>
      _wrapRole(this, (theme) => theme.typography.displayLarge);

  /// Display medium semantic text style.
  TextModifier get displayMedium =>
      _wrapRole(this, (theme) => theme.typography.displayMedium);

  /// Display small semantic text style.
  TextModifier get displaySmall =>
      _wrapRole(this, (theme) => theme.typography.displaySmall);

  /// Headline large semantic text style.
  TextModifier get headlineLarge =>
      _wrapRole(this, (theme) => theme.typography.headlineLarge);

  /// Headline medium semantic text style.
  TextModifier get headlineMedium =>
      _wrapRole(this, (theme) => theme.typography.headlineMedium);

  /// Headline small semantic text style.
  TextModifier get headlineSmall =>
      _wrapRole(this, (theme) => theme.typography.headlineSmall);

  /// Title large semantic text style.
  TextModifier get titleLarge =>
      _wrapRole(this, (theme) => theme.typography.titleLarge);

  /// Title medium semantic text style.
  TextModifier get titleMedium =>
      _wrapRole(this, (theme) => theme.typography.titleMedium);

  /// Title small semantic text style.
  TextModifier get titleSmall =>
      _wrapRole(this, (theme) => theme.typography.titleSmall);

  /// Body large semantic text style.
  TextModifier get bodyLarge =>
      _wrapRole(this, (theme) => theme.typography.bodyLarge);

  /// Body medium semantic text style.
  TextModifier get bodyMedium =>
      _wrapRole(this, (theme) => theme.typography.bodyMedium);

  /// Body small semantic text style.
  TextModifier get bodySmall =>
      _wrapRole(this, (theme) => theme.typography.bodySmall);

  /// Body xs semantic text style — the smallest body rung (help text,
  /// captions).
  TextModifier get bodyXs =>
      _wrapRole(this, (theme) => theme.typography.bodyXs);

  /// Label xl2 semantic text style — the largest control-label rung.
  TextModifier get labelXl2 =>
      _wrapRole(this, (theme) => theme.typography.labelXl2);

  /// Label xl semantic text style.
  TextModifier get labelXl =>
      _wrapRole(this, (theme) => theme.typography.labelXl);

  /// Label large semantic text style.
  TextModifier get labelLarge =>
      _wrapRole(this, (theme) => theme.typography.labelLarge);

  /// Label medium semantic text style.
  TextModifier get labelMedium =>
      _wrapRole(this, (theme) => theme.typography.labelMedium);

  /// Label small semantic text style.
  TextModifier get labelSmall =>
      _wrapRole(this, (theme) => theme.typography.labelSmall);

  /// Label xs semantic text style — the smallest control-label rung.
  TextModifier get labelXs =>
      _wrapRole(this, (theme) => theme.typography.labelXs);

  /// Code xs semantic text style — the smallest monospace role, on the
  /// code roles' shared fixed line box.
  TextModifier get codeXs =>
      _wrapRole(this, (theme) => theme.typography.codeXs);

  /// Code sm semantic text style — monospace on the code roles' shared
  /// fixed line box.
  TextModifier get codeSm =>
      _wrapRole(this, (theme) => theme.typography.codeSm);

  /// Code md semantic text style — the largest monospace role, on the code
  /// roles' shared fixed line box. A later size modifier keeps the box
  /// (`.codeMd.s16` still draws a 21px line); a later `.h*` replaces it.
  TextModifier get codeMd =>
      _wrapRole(this, (theme) => theme.typography.codeMd);

  /// Colours the text with the colour scheme's `onSurface` role —
  /// the default foreground.
  TextModifier get foreground => _wrapChain(
    this,
    (context, theme) => TextStyle(
      color: theme.colorScheme.onSurface.toValue(),
    ),
  );

  /// Appends [span] after this widget as one rich-text run.
  Widget then(InlineSpan span) {
    if (this is RichText) {
      final text = this as RichText;

      return _RichTextThenWidget(text: text, then: [span]);
    }
    if (this is SelectableText) {
      final text = this as SelectableText;

      return _SelectableTextThenWidget(text: text, then: [span]);
    }
    if (this is Text) {
      final text = this as Text;

      return _TextThenWidget(text: text, then: [span]);
    }
    if (this is _RichTextThenWidget) {
      final text = this as _RichTextThenWidget;

      return _RichTextThenWidget(
        text: text.text,
        then: [...text.then, span],
      );
    }
    if (this is _TextThenWidget) {
      final text = this as _TextThenWidget;

      return _TextThenWidget(text: text.text, then: [...text.then, span]);
    }
    if (this is _SelectableTextThenWidget) {
      final text = this as _SelectableTextThenWidget;

      return _SelectableTextThenWidget(
        text: text.text,
        then: [...text.then, span],
      );
    }
    // 체인 modifier 수신자(WrappedText 등 non-Text)는 여기로 fall-through 한다.
    // WidgetSpan 기본 정렬(bottom)은 관례상 .middle 로 붙는 후속 스팬과 수직
    // 기준이 달라 세그먼트가 어긋난다 — thenInlineCode 와 같은
    // .middle 로 통일한다 (#3256).
    final currentSpan = WidgetSpan(alignment: .middle, child: this);

    return RichText(text: TextSpan(children: [currentSpan, span]));
  }

  /// Appends [text] as a plain span.
  Widget thenText(String text) {
    return then(TextSpan(text: text));
  }

  /// Appends an inline [Link] — [Link.inlineSpan] — after this widget as one
  /// rich-text run.
  ///
  /// The link wraps across lines with the words around it and takes its size
  /// and weight from the paragraph; only the colour comes from [linkStyle].
  /// It is always underlined, and a span is not a focusable node, so use the
  /// [Link] widget where the link must be reachable by Tab.
  ///
  /// The label is [text], or [children] when the link text itself carries
  /// inline styling. With neither, [href] is shown.
  ///
  /// Unlike calling [Link.inlineSpan] yourself, there is no `recognizers`
  /// list to keep: the tap recognizer [onPressed] needs is owned by a
  /// `State` this method returns and disposed with it.
  Widget thenLink({
    required String href,
    String? text,
    List<InlineSpan>? children,
    VoidCallback? onPressed,
    bool external = false,
    CoreLinkVariant variant = CoreLinkVariant.defaultVariant,
    CoreLinkStyle? linkStyle,
  }) {
    return _ThenLink(
      source: this,
      href: href,
      text: text,
      onPressed: onPressed,
      external: external,
      variant: variant,
      linkStyle: linkStyle,
      children: children,
    );
  }

  // ==========================================================================
  // Cross-platform chain methods — match `coui_web` `TextExtension on
  // Component` 1:1 so application code reads identically on both
  // platforms. Each method wraps the receiver in a new `WrappedText`
  // carrying only that property; chains compose via inside-out merge.
  // ==========================================================================

  /// Sets the foreground colour to [value].
  Widget color(CoreColor value) => _wrapChain(
    this,
    (context, theme) =>
        TextStyle(color: theme.colorScheme.resolve(value).toValue()),
  );

  /// Multiplies the foreground colour alpha by [value] (`0..1`).
  ///
  /// When the upstream chain has set an explicit colour (via [color] or a
  /// semantic colour shortcut), this scales that colour's alpha. When no
  /// colour is set, it falls back to scaling the inherited
  /// `DefaultTextStyle` colour.
  Widget opacity(double value) {
    final self = this;
    return _wrapChain(self, (context, theme) {
      // 누적된 chain 의 color 를 우선 시도 — `_wrapChain` 으로 chain 이
      // 단일 WrappedText 위에 합쳐졌다면 자기 builder 를 호출해 이전
      // chain 의 color 를 추출한다. 없으면 ancestor DefaultTextStyle,
      // 그것도 없으면 onSurface fallback.
      final upstreamColor = self is WrappedText
          ? self.style?.call(context, theme)?.color
          : null;
      final base =
          upstreamColor ??
          DefaultTextStyle.of(context).style.color ??
          theme.colorScheme.onSurface.toValue();
      return TextStyle(color: base.withValues(alpha: value));
    });
  }

  /// Sets the explicit font size in logical pixels.
  Widget fontSize(double value) =>
      _wrapChain(this, (context, theme) => TextStyle(fontSize: value));

  /// Sets the font weight (CSS-numeric `100..900`, matching
  /// `CoreFontWeight.semiBold` / `CoreFontWeight.medium` / etc).
  Widget fontWeight(int value) => _wrapChain(
    this,
    (context, theme) => TextStyle(fontWeight: _coreFontWeightToFlutter(value)),
  );

  /// Sets the explicit line-height multiplier. Like the `.h*` getters it
  /// is the newest line-height statement, so it replaces a code role's
  /// fixed line box.
  Widget lineHeight(double value) => _wrapLineHeight(this, value);

  /// Sets the explicit letter spacing in `em`. Flutter's `letterSpacing`
  /// is in logical pixels; `em` is converted using the resolved font
  /// size at build time (chain 머지가 끝난 뒤 최종 `fontSize` 기준).
  Widget letterSpacing(double value) => _wrapLetterSpacingEm(this, value);

  /// Sets the text decoration.
  Widget decoration(CoreTextDecoration value) => _wrapChain(
    this,
    (context, theme) => TextStyle(decoration: _coreDecorationToFlutter(value)),
  );

  /// Sets the colour of the text decoration line.
  Widget decorationColor(CoreColor value) => _wrapChain(
    this,
    (context, theme) =>
        TextStyle(decorationColor: theme.colorScheme.resolve(value).toValue()),
  );

  /// Overrides the accessible label.
  Widget semanticsLabel(String value) => Semantics(label: value, child: this);

  /// Clamps the text to at most [maxLines] lines. Named after SwiftUI's
  /// `.lineLimit(_)`; a non-field name (unlike the `maxLines` field,
  /// which would shadow a same-named method) so it is reachable directly
  /// on a bare `Text` as well as after a typography hop. Mirrors the Web
  /// `Text('...').lineLimit(n)` chain so application code reads
  /// identically on both platforms. The clamp threads to the rendered
  /// child `Text` via the ambient `DefaultTextStyle` (Flutter `Text`
  /// inherits `maxLines` when its own is unset).
  TextModifier lineLimit(int maxLines) => _wrapMaxLines(this, maxLines);

  /// Truncates overflowing text with an ellipsis (`…`)
  /// (`CoreTextOverflow.ellipsis`). Mirrors the Web `Text('...').ellipsis`
  /// getter. The resolved Flutter `TextOverflow` threads to the rendered
  /// child `Text` via the ambient `DefaultTextStyle`.
  TextModifier get ellipsis =>
      _wrapOverflow(this, CoreTextOverflow.ellipsis.toValue());

  // NOTE — there is intentionally no clip overflow getter here. The name
  // collides with the existing layout clip extension on Widget (a clip
  // method taking a clipBehavior), which would make every clip access an
  // ambiguous extension member access error. Clip is Flutter's default
  // overflow anyway, so pass it through the Text widget's overflow named
  // parameter directly when needed. The Web side omits clip too, keeping
  // the chain API identical on both platforms.

  /// Fades overflowing text out (`CoreTextOverflow.fade`). Mirrors the
  /// Web `Text('...').fade` getter.
  TextModifier get fade => _wrapOverflow(this, CoreTextOverflow.fade.toValue());

  /// Renders overflowing text outside its bounds without clipping
  /// (`CoreTextOverflow.visible`). Mirrors the Web `Text('...').visible`
  /// getter.
  TextModifier get visible =>
      _wrapOverflow(this, CoreTextOverflow.visible.toValue());

  /// Breaks lines between words only — CSS `word-break: keep-all`, the
  /// convention for Korean. A word wider than the line still breaks
  /// inside, as Web `overflow-wrap: anywhere` does. Mirrors the Web
  /// `Text('...').keepAll` getter.
  ///
  /// Reaches the `Text` this chain wraps (its `data`, or the `TextSpan`
  /// texts of `Text.rich`), drawn from [CoreKeepAll]'s display string;
  /// any other widget passes through unchanged. What is announced and
  /// copied stays the original string.
  TextModifier get keepAll => _wrapKeepAll(this);
}

FontWeight _coreFontWeightToFlutter(int weight) {
  return switch (weight) {
    CoreFontWeight.thin => FontWeight.w100,
    CoreFontWeight.extraLight => FontWeight.w200,
    CoreFontWeight.light => FontWeight.w300,
    CoreFontWeight.medium => FontWeight.w500,
    CoreFontWeight.semiBold => FontWeight.w600,
    CoreFontWeight.bold => FontWeight.w700,
    CoreFontWeight.extraBold => FontWeight.w800,
    CoreFontWeight.black => FontWeight.w900,
    _ => FontWeight.w400,
  };
}

TextDecoration _coreDecorationToFlutter(CoreTextDecoration value) =>
    switch (value) {
      .none => .none,
      .underline => .underline,
      .overline => .overline,
      .lineThrough => .lineThrough,
    };

/// Owns the tap recognizer a [Link.inlineSpan] needs, so `thenLink` can be
/// written without a `State` of the caller's.
class _ThenLink extends StatefulWidget {
  const _ThenLink({
    required this.source,
    required this.href,
    required this.text,
    required this.onPressed,
    required this.external,
    required this.variant,
    required this.linkStyle,
    required this.children,
  });

  /// The widget the link is appended to.
  final Widget source;

  final String href;

  final String? text;

  final VoidCallback? onPressed;

  final bool external;

  final CoreLinkVariant variant;

  final CoreLinkStyle? linkStyle;

  final List<InlineSpan>? children;

  @override
  State<_ThenLink> createState() => _ThenLinkState();
}

class _ThenLinkState extends State<_ThenLink> {
  final List<GestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A recognizer belongs to the span it was built for, so each build
    // starts from none — the owner contract `Link.inlineSpan` documents.
    _disposeRecognizers();

    return widget.source.then(
      Link.inlineSpan(
        context,
        href: widget.href,
        text: widget.text,
        children: widget.children,
        onPressed: widget.onPressed,
        external: widget.external,
        variant: widget.variant,
        linkStyle: widget.linkStyle,
        recognizers: _recognizers,
      ),
    );
  }
}

class _TextThenWidget extends StatelessWidget {
  const _TextThenWidget({required this.text, required this.then});

  final Text text;

  final List<InlineSpan> then;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    var effectiveTextStyle = text.style;
    if (text.style == null || text.style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(text.style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle!.merge(
        TextStyle(fontWeight: CoreFontWeight.bold.weight),
      );
    }
    final registrar = SelectionContainer.maybeOf(context);
    Widget result = RichText(
      text: TextSpan(
        style: effectiveTextStyle,
        children: [
          TextSpan(text: text.data),
          ...then,
        ],
      ),
      textAlign: text.textAlign ?? defaultTextStyle.textAlign ?? .start,
      textDirection: text.textDirection,
      softWrap: text.softWrap ?? defaultTextStyle.softWrap,
      overflow:
          text.overflow ??
          effectiveTextStyle?.overflow ??
          defaultTextStyle.overflow,
      textScaler: text.textScaler ?? .noScaling,
      maxLines: text.maxLines ?? defaultTextStyle.maxLines,
      locale: text.locale,
      strutStyle: text.strutStyle,
      textWidthBasis: text.textWidthBasis ?? defaultTextStyle.textWidthBasis,
      textHeightBehavior:
          text.textHeightBehavior ??
          defaultTextStyle.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
      selectionRegistrar: registrar,
      selectionColor:
          text.selectionColor ??
          DefaultSelectionStyle.of(context).selectionColor ??
          DefaultSelectionStyle.defaultColor,
    );
    if (registrar != null) {
      result = MouseRegion(
        cursor:
            DefaultSelectionStyle.of(context).mouseCursor ??
            SystemMouseCursors.text,
        child: result,
      );
    }
    if (text.semanticsLabel != null) {
      result = Semantics(
        label: text.semanticsLabel,
        textDirection: text.textDirection,
        child: ExcludeSemantics(child: result),
      );
    }

    return result;
  }
}

class _RichTextThenWidget extends StatelessWidget {
  const _RichTextThenWidget({required this.text, required this.then});

  final RichText text;

  final List<InlineSpan> then;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [text.text, ...then]),
      textAlign: text.textAlign,
      textDirection: text.textDirection,
      softWrap: text.softWrap,
      overflow: text.overflow,
      textScaler: text.textScaler,
      maxLines: text.maxLines,
      locale: text.locale,
      strutStyle: text.strutStyle,
      textWidthBasis: text.textWidthBasis,
      textHeightBehavior: text.textHeightBehavior,
      selectionRegistrar: text.selectionRegistrar,
      selectionColor: text.selectionColor,
    );
  }
}

class _SelectableTextThenWidget extends StatelessWidget {
  const _SelectableTextThenWidget({required this.text, required this.then});

  final SelectableText text;

  final List<InlineSpan> then;

  @override
  Widget build(BuildContext context) {
    final stringData = text.data;
    final textData = text.textSpan;

    // Args are alphabetically sorted (onTap first); this is Flutter Material's
    // SelectableText.rich (30 params) and matching its declaration order would
    // be far less readable.
    return SelectableText.rich(
      TextSpan(
        text: stringData,
        children: [?textData, ...then],
      ),
      onTap: text.onTap,
      autofocus: text.autofocus,
      contextMenuBuilder: text.contextMenuBuilder,
      cursorColor: text.cursorColor,
      cursorHeight: text.cursorHeight,
      cursorRadius: text.cursorRadius,
      cursorWidth: text.cursorWidth,
      dragStartBehavior: text.dragStartBehavior,
      enableInteractiveSelection: text.enableInteractiveSelection,
      focusNode: text.focusNode,
      magnifierConfiguration: text.magnifierConfiguration,
      maxLines: text.maxLines,
      minLines: text.minLines,
      onSelectionChanged: text.onSelectionChanged,
      scrollPhysics: text.scrollPhysics,
      selectionControls: text.selectionControls,
      selectionHeightStyle: text.selectionHeightStyle,
      selectionWidthStyle: text.selectionWidthStyle,
      semanticsLabel: text.semanticsLabel,
      showCursor: text.showCursor,
      strutStyle: text.strutStyle,
      style: text.style,
      textAlign: text.textAlign,
      textDirection: text.textDirection,
      textHeightBehavior: text.textHeightBehavior,
      textScaler: text.textScaler,
      textWidthBasis: text.textWidthBasis,
    );
  }
}

/// Resolves a chain value from the build context and theme at build time.
typedef WrappedTextDataBuilder<T> =
    T Function(BuildContext context, ThemeData theme);

/// Wraps a chain's child in another widget at build time.
typedef WidgetTextWrapper = Widget Function(BuildContext context, Widget child);

/// What a Text chain builds: the accumulated style and the Text-level
/// slots, laid onto [child] through `DefaultTextStyle` at build time.
class WrappedText extends StatelessWidget implements TextModifier {
  /// Creates a [WrappedText]. The chain getters build these; construct one
  /// directly only when composing a chain by hand.
  const WrappedText({
    required this.child,
    super.key,
    this.hasRole = false,
    this.letterSpacingEm,
    this.lineHeightPx,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.style,
    this.textAlign,
    this.textWidthBasis,
    this.wordBreakKeepAll = false,
    this.wrapper,
  });

  /// The widget the chain applies to — usually a `Text`.
  final Widget child;

  /// The accumulated chain style, resolved at build time.
  final WrappedTextDataBuilder<TextStyle?>? style;

  /// Whether the chain names a semantic typography role (`.bodyMedium`,
  /// `.titleLarge`, …).
  ///
  /// A role states the whole text style, so the chain starts from CoUI's
  /// typography baseline (`bodyMedium` + `onSurface`) with the role layered
  /// on top. A chain without a role — weight, colour, size, decoration
  /// only — overrides just the properties it names and inherits the rest
  /// from the ambient `DefaultTextStyle`, the same way the Web `Text`
  /// emits only the classes/inline CSS it was given and lets the cascade
  /// supply the rest.
  final bool hasRole;

  /// Horizontal alignment set by the chain.
  final WrappedTextDataBuilder<TextAlign?>? textAlign;

  /// Whether lines break at soft wrap opportunities.
  final WrappedTextDataBuilder<bool?>? softWrap;

  /// How overflowing text is drawn — set by `.ellipsis`, `.fade` or
  /// `.visible`.
  final WrappedTextDataBuilder<TextOverflow?>? overflow;

  /// The line clamp set by `.lineLimit`.
  final WrappedTextDataBuilder<int?>? maxLines;

  /// How the width of the text is measured.
  final WrappedTextDataBuilder<TextWidthBasis?>? textWidthBasis;

  /// Letter spacing in `em` resolved at build time against the merged
  /// chain's final `fontSize`, mirroring Web `letter-spacing: <em>`
  /// semantics. Later chain calls override earlier ones.
  final WrappedTextDataBuilder<double?>? letterSpacingEm;

  /// The fixed line box a role states, in logical pixels — the code roles'
  /// 21px; null for a multiplier role.
  ///
  /// Flutter's `height` is a multiplier of the font size, so a box baked
  /// into the role's `TextStyle` would scale with any later size modifier
  /// (`.codeMd.s16` would draw a 25.8px line) while the Web keeps the box.
  /// It is resolved here instead, at build time against the merged chain's
  /// final `fontSize`, the way [letterSpacingEm] is. Every role restates
  /// it; a later line-height statement (`.h*`, `.lineHeight(v)`, a `height`
  /// passed to [call]) clears it, so the newest statement is the one drawn.
  final WrappedTextDataBuilder<double?>? lineHeightPx;

  /// Whether the chain breaks lines between words only — CSS
  /// `word-break: keep-all`, set by `.keepAll`. Named apart from the chain
  /// getter: an instance member would shadow the extension getter on a
  /// [WrappedText] receiver, the way a `maxLines` field would shadow a
  /// `maxLines(...)` chain.
  ///
  /// Flutter has no line-breaking mode to set, so the wrapper redraws its
  /// child — when the child is a `Text` — from [CoreKeepAll]'s display
  /// string, which holds each word together with U+2060 WORD JOINER. The
  /// original string stays what is announced (`semanticsLabel`) and, under
  /// a selection area, what is copied. Any other child passes through.
  final bool wordBreakKeepAll;

  /// Wraps the child in another widget at build time.
  final WidgetTextWrapper? wrapper;

  @override
  Widget call({
    Paint? background,
    Color? backgroundColor,
    Color? color,
    String? debugLabel,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    List<FontFeature>? fontFeatures,
    double? fontSize,
    FontStyle? fontStyle,
    List<FontVariation>? fontVariations,
    FontWeight? fontWeight,
    Paint? foreground,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    double? letterSpacing,
    Locale? locale,
    TextOverflow? overflow,
    String? package,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
    double? wordSpacing,
  }) {
    final chained = copyWithStyle(
      (context, theme) => TextStyle(
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        leadingDistribution: leadingDistribution,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        debugLabel: debugLabel,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        package: package,
        overflow: overflow,
      ),
    );

    // A stated height is the newest line-height statement — it replaces a
    // role's fixed line box rather than being overwritten by it at build.
    return height == null ? chained : chained.copyWithLineHeightPx(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chain = style?.call(context, theme);
    final ambient = DefaultTextStyle.of(context).style;
    // A role chain restates the whole text style, so it starts from CoUI's
    // typography baseline (`bodyMedium` + `onSurface`) and the role layers
    // on top — the baseline only fills what the role itself leaves unset.
    // Any other chain (weight / colour / size / decoration …) is a partial
    // override: it merges onto the ambient `DefaultTextStyle` and every
    // property it does not name is inherited, matching the Web `Text`,
    // which emits only what the chain set and lets the cascade supply the
    // rest.
    var merged = hasRole
        ? theme.typography.bodyMedium
              .toValue(theme: theme)
              .copyWith(color: theme.colorScheme.onSurface.toValue())
              .merge(chain)
        : chain ?? const TextStyle();

    // Flutter Web (특히 HTML renderer) 은 `decorationColor: null` 시 자동
    // currentColor fallback 이 일관되지 않다. chain 누적 결과 decoration 이
    // 있는데 decorationColor 가 비어있으면 chain 의 text color 를 명시적
    // 으로 박아서 underline/lineThrough/overline 가 항상 text color 로
    // 그려지도록 보장 (Web `text-decoration-color: currentColor` 와 동등).
    final decoration = merged.decoration;
    final color = merged.color ?? ambient.color;
    if (decoration != null &&
        decoration != .none &&
        merged.decorationColor == null &&
        color != null) {
      merged = merged.copyWith(decorationColor: color);
    }

    // Resolve em-based letterSpacing against the merged final fontSize so
    // chains like `.s32.tighter` produce identical spacing to Web's
    // `letter-spacing: -0.05em` at 32px (= -1.6px). A chain without its own
    // size resolves against the inherited one. When unset, the role's (or
    // the inherited) already-converted px letterSpacing remains in effect.
    final em = letterSpacingEm?.call(context, theme);
    final fontSize = merged.fontSize ?? ambient.fontSize ?? CoreFontSize.s14;
    if (em != null) {
      merged = merged.copyWith(letterSpacing: em * fontSize);
    }

    // A role's fixed line box resolves against the same final size, so a
    // later size modifier keeps the line where the Web keeps it
    // (`.codeMd.s16` still draws 21px).
    final lineBox = lineHeightPx?.call(context, theme);
    if (lineBox != null && fontSize > 0) {
      merged = merged.copyWith(height: lineBox / fontSize);
    }

    final content = wordBreakKeepAll ? keepAllContent(context, child) : child;

    return DefaultTextStyle.merge(
      style: merged,
      textAlign: textAlign?.call(context, theme),
      softWrap: softWrap?.call(context, theme),
      overflow: overflow?.call(context, theme),
      maxLines: maxLines?.call(context, theme),
      textWidthBasis: textWidthBasis?.call(context, theme),
      child: wrapper?.call(context, content) ?? content,
    );
  }

  /// Returns a new [WrappedText] whose [style] layers [style] on top of
  /// the existing chain. [role] marks the added layer as a semantic
  /// typography role (see [hasRole]); once a chain carries a role it keeps
  /// it.
  WrappedText copyWithStyle(
    WrappedTextDataBuilder<TextStyle> style, {
    bool role = false,
  }) {
    return WrappedText(
      hasRole: hasRole || role,
      letterSpacingEm: letterSpacingEm,
      lineHeightPx: lineHeightPx,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      // 새로 들어오는 [style] 이 기존 chain 위에 덮인다 — chain 호출
      // 순서상 나중에 호출된 modifier 가 우선되도록 (= copyWith 시멘틱).
      style: (context, theme) =>
          (this.style?.call(context, theme) ?? const TextStyle()).merge(
            style(context, theme),
          ),
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      wordBreakKeepAll: wordBreakKeepAll,
      wrapper: wrapper,
      child: child,
    );
  }

  /// Returns a new [WrappedText] whose [letterSpacingEm] resolves to the
  /// override [em] value, replacing any prior em (chain copyWith semantics).
  /// Other chain props are preserved untouched.
  WrappedText copyWithLetterSpacingEm(WrappedTextDataBuilder<double?> em) {
    return WrappedText(
      hasRole: hasRole,
      letterSpacingEm: em,
      lineHeightPx: lineHeightPx,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style,
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      wordBreakKeepAll: wordBreakKeepAll,
      wrapper: wrapper,
      child: child,
    );
  }

  /// Returns a new [WrappedText] whose [lineHeightPx] is [lineHeightPx],
  /// replacing any prior box — null clears it. A role restates its box
  /// this way; a later line-height multiplier clears it. Other chain props
  /// are preserved untouched.
  WrappedText copyWithLineHeightPx(
    WrappedTextDataBuilder<double?>? lineHeightPx,
  ) {
    return WrappedText(
      hasRole: hasRole,
      letterSpacingEm: letterSpacingEm,
      lineHeightPx: lineHeightPx,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style,
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      wordBreakKeepAll: wordBreakKeepAll,
      wrapper: wrapper,
      child: child,
    );
  }

  /// Returns a new [WrappedText] whose [maxLines] resolves to the
  /// override [maxLines] value, replacing any prior clamp (chain
  /// copyWith semantics). Other chain props are preserved untouched.
  WrappedText copyWithMaxLines(WrappedTextDataBuilder<int?> maxLines) {
    return WrappedText(
      hasRole: hasRole,
      letterSpacingEm: letterSpacingEm,
      lineHeightPx: lineHeightPx,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style,
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      wordBreakKeepAll: wordBreakKeepAll,
      wrapper: wrapper,
      child: child,
    );
  }

  /// Returns a new [WrappedText] whose [overflow] resolves to the
  /// override [overflow] value, replacing any prior overflow (chain
  /// copyWith semantics). Other chain props are preserved untouched.
  WrappedText copyWithOverflow(WrappedTextDataBuilder<TextOverflow?> overflow) {
    return WrappedText(
      hasRole: hasRole,
      letterSpacingEm: letterSpacingEm,
      lineHeightPx: lineHeightPx,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style,
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      wordBreakKeepAll: wordBreakKeepAll,
      wrapper: wrapper,
      child: child,
    );
  }

  /// Returns a new [WrappedText] with [wordBreakKeepAll] on. Other chain
  /// props are preserved untouched.
  WrappedText copyWithKeepAll() {
    return WrappedText(
      hasRole: hasRole,
      letterSpacingEm: letterSpacingEm,
      lineHeightPx: lineHeightPx,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style,
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      wordBreakKeepAll: true,
      wrapper: wrapper,
      child: child,
    );
  }
}

// ============================================================================
// Text Color Style Modifiers
// Enables chained color styling: Text('Hello').onPrimaryContainer
// ============================================================================

/// Color modifier for Text that applies a semantic colour token, e.g.
/// `Text('Hello').onPrimaryContainer` or
/// `Text('Hello').onPrimaryContainer.opacity(0.1)`.
class TextColorModifier extends StatelessWidget implements TextModifier {
  /// Creates a modifier that colours the child with the colour the lookup
  /// returns.
  const TextColorModifier(this._child, this._colorGetter, {super.key});

  final Widget _child;
  final Color Function(ColorScheme colorScheme) _colorGetter;

  @override
  Widget call({
    Paint? background,
    Color? backgroundColor,
    Color? color,
    String? debugLabel,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    List<FontFeature>? fontFeatures,
    double? fontSize,
    FontStyle? fontStyle,
    List<FontVariation>? fontVariations,
    FontWeight? fontWeight,
    Paint? foreground,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    double? letterSpacing,
    Locale? locale,
    TextOverflow? overflow,
    String? package,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
    double? wordSpacing,
  }) {
    return WrappedText(
      style: (context, theme) => TextStyle(
        color: color ?? _colorGetter(theme.colorScheme),
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        leadingDistribution: leadingDistribution,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        debugLabel: debugLabel,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        package: package,
        overflow: overflow,
      ),
      child: _child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTextStyle.merge(
      style: TextStyle(color: _colorGetter(theme.colorScheme)),
      child: _child,
    );
  }
}
