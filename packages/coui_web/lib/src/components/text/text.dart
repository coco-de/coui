import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/text/font_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide FontStyle, Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Base class for inline span nodes inside a [Text.rich] subtree.
/// Mirrors Flutter `InlineSpan`. For now only [TextSpan] is supported
/// (Flutter's `WidgetSpan` would map to inline-block embedded
/// components — out of scope for the initial unification).
abstract class InlineSpan {
  /// Creates an inline span.
  const InlineSpan({this.style});

  /// Optional style applied to this span (and inherited by descendant
  /// spans unless overridden).
  final TextStyle? style;
}

/// Run of styled text that participates in a [Text.rich] tree. Mirrors
/// Flutter `TextSpan` parameter names so user code reads identically on
/// both platforms; only field types differ where the underlying
/// platform API differs.
class TextSpan extends InlineSpan {
  /// Creates a [TextSpan].
  const TextSpan({
    this.text,
    this.children,
    super.style,
    this.semanticsLabel,
    this.locale,
  });

  /// Literal text emitted by this span.
  final String? text;

  /// Optional nested spans rendered after [text].
  final List<InlineSpan>? children;

  /// Optional accessibility label override for this span.
  final String? semanticsLabel;

  /// BCP 47 locale tag for this span (HTML `lang` attribute).
  final String? locale;
}

/// Drop-shadow descriptor. Mirrors Flutter `Shadow` parameter names so
/// user code reads identically on both platforms; only the value types
/// differ (Web stores tokens / raw doubles instead of `Color` / `Offset`).
///
/// ```dart
/// Shadow(color: 'shadow', offset: (dx: 0, dy: 1), blurRadius: 2)
/// ```
class Shadow {
  /// Creates a drop-shadow descriptor.
  const Shadow({
    this.color,
    this.offset = (dx: 0, dy: 0),
    this.blurRadius = 0,
  });

  /// Tailwind color token for the shadow.
  ///
  /// **Type difference**: Flutter SDK uses `Color`; Web uses Tailwind
  /// token string for theme-driven CSS variable mapping.
  final String? color;

  /// (dx, dy) offset in CSS px. Mirrors Flutter `Shadow.offset`.
  ///
  /// **Type difference**: Flutter SDK uses `Offset`; Web uses a record
  /// (`(dx: double, dy: double)`).
  final ({double dx, double dy}) offset;

  /// Gaussian blur radius in CSS px. Mirrors Flutter `Shadow.blurRadius`.
  final double blurRadius;
}

/// Web text style — string-token bag with **the same parameter names
/// as Flutter SDK `TextStyle`** so user code reads identically on both
/// platforms; only the field types differ (Web stores Tailwind tokens
/// as `String`, Flutter stores `Color` / `FontWeight` objects).
///
/// ```dart
/// // Same prop names on both platforms.
/// TextStyle(fontSize: CoreFontSize.s14, fontWeight: '600', color: 'primary')
/// ```
///
/// To apply a full semantic typography token, use the chain API
/// (`Text('...').bodyMedium`) — analogous to Flutter's
/// `Text('...').bodyMedium`. The chain getters pull from
/// `CoreTypography.coui` (see `text_extension.dart`).
class TextStyle {
  /// Creates a [TextStyle] with the given fields. All fields are
  /// optional; null fields fall through to the inherited base style.
  const TextStyle({
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
    this.role,
    this.wordBreakKeepAll,
  });

  /// Tailwind color token (e.g. `'primary'`, `'on-surface'`,
  /// `'error'`). Maps to `text-${color}` class.
  ///
  /// **Type difference**: Flutter SDK uses `Color`; Web uses Tailwind
  /// token string for theme-driven CSS variable mapping.
  final String? color;

  /// Tailwind background-color token. Maps to `bg-${backgroundColor}`.
  final String? backgroundColor;

  /// Font size in pixels (raw value, e.g. `CoreFontSize.s14`). Mirrors
  /// Flutter `TextStyle.fontSize`.
  final double? fontSize;

  /// Tailwind font-weight token (e.g. `'semibold'`, `'bold'` from
  /// `CoreFontWeight.scale`). Maps to `font-${fontWeight}` class.
  ///
  /// **Type difference**: Flutter SDK uses `FontWeight`; Web uses
  /// Tailwind weight token string.
  final String? fontWeight;

  /// Font style — `'italic'` / `'normal'`. Mirrors Flutter
  /// `TextStyle.fontStyle`.
  ///
  /// **Type difference**: Flutter SDK uses `FontStyle` enum; Web uses
  /// the CSS keyword string directly.
  final FontStyle? fontStyle;

  /// Font family token (`'sans'` / `'mono'` from `CoreFontFamily.scale`).
  /// Maps to `font-${fontFamily}` class.
  final String? fontFamily;

  /// Letter spacing in em (raw value). Mirrors Flutter
  /// `TextStyle.letterSpacing` (Web 단위는 em, Flutter 는 logical px —
  /// 다른 컴포넌트의 단위 차이 패턴과 동일).
  final double? letterSpacing;

  /// Word spacing in em (raw value). Mirrors Flutter
  /// `TextStyle.wordSpacing`.
  final double? wordSpacing;

  /// Line-height multiplier (e.g. `1.6`). Mirrors Flutter
  /// `TextStyle.height`.
  final double? height;

  /// Text decoration enum (`CoreTextDecoration.underline` etc.).
  /// Mirrors Flutter `TextStyle.decoration`.
  final CoreTextDecoration? decoration;

  /// Decoration color token. Maps to `decoration-${decorationColor}`.
  final String? decorationColor;

  /// Style of the decoration line (solid / double / dotted / dashed /
  /// wavy). Mirrors Flutter `TextStyle.decorationStyle`.
  final CoreTextDecorationStyle? decorationStyle;

  /// Thickness of the decoration line in px. Mirrors Flutter
  /// `TextStyle.decorationThickness`.
  final double? decorationThickness;

  /// Drop-shadow list. Mirrors Flutter `TextStyle.shadows`.
  final List<Shadow>? shadows;

  /// Semantic typography role (`CoreTextStyleToken.name`, e.g.
  /// `'body-medium'`) — emits the single `text-{role}` Tailwind class
  /// instead of baking [fontSize]/[fontWeight]/[height]/[letterSpacing] as
  /// literals. That class already references
  /// `var(--coui-text-{role}-size/-line-height/-weight/-tracking)`
  /// (`ThemeConfig._semanticFontSizeConfig`), so the role stays reactive to
  /// runtime CSS-variable overrides — project `theme.typography` and
  /// surface-style weight floors (`[data-coui-style="..."]` blocks) — with
  /// zero Dart rebuild. Set by the semantic chain getters (`.bodyMedium`
  /// etc, see `text_extension.dart`); the four raw fields above remain the
  /// primitive-override channel (`.s14`, `.bold`, `.h140`,
  /// `.letterSpacing(...)`) and win per-property over the role class when
  /// chained after it (inline beats class for that one CSS property).
  final String? role;

  /// Breaks lines between words only — emits `word-break: keep-all` with
  /// `overflow-wrap: anywhere`, so a word wider than the line still breaks
  /// inside it. Set by the `.keepAll` chain (see `text_extension.dart`)
  /// and read at the `Text` root only — the CSS inherits into every span
  /// of a `Text.rich`, and a `TextSpan.style` value is not read. The
  /// string itself is never changed; Flutter, which has no such property,
  /// reaches the same lines through `CoreKeepAll`.
  final bool? wordBreakKeepAll;

  /// Returns a copy with the given fields replaced.
  TextStyle copyWith({
    String? color,
    String? backgroundColor,
    double? fontSize,
    String? fontWeight,
    FontStyle? fontStyle,
    String? fontFamily,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    CoreTextDecoration? decoration,
    String? decorationColor,
    CoreTextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<Shadow>? shadows,
    String? role,
    bool? wordBreakKeepAll,
  }) {
    return TextStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      height: height ?? this.height,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      decorationThickness: decorationThickness ?? this.decorationThickness,
      shadows: shadows ?? this.shadows,
      role: role ?? this.role,
      wordBreakKeepAll: wordBreakKeepAll ?? this.wordBreakKeepAll,
    );
  }

  /// Returns this style under [role] — a role states the whole text style,
  /// so the size, weight, line height and family a chain set before it are
  /// dropped and the role class carries them. Letter spacing, slant,
  /// colour and decoration are kept, as Flutter's role getter keeps them
  /// (its letter-spacing chain lives in a slot the role does not touch).
  TextStyle withRole(String role) {
    return TextStyle(
      color: color,
      backgroundColor: backgroundColor,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      shadows: shadows,
      role: role,
      wordBreakKeepAll: wordBreakKeepAll,
    );
  }

  /// Merges [other] into this — [other]'s non-null fields win.
  TextStyle merge(TextStyle? other) {
    if (other == null) return this;
    return copyWith(
      color: other.color,
      backgroundColor: other.backgroundColor,
      fontSize: other.fontSize,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      fontFamily: other.fontFamily,
      letterSpacing: other.letterSpacing,
      wordSpacing: other.wordSpacing,
      height: other.height,
      decoration: other.decoration,
      decorationColor: other.decorationColor,
      decorationStyle: other.decorationStyle,
      decorationThickness: other.decorationThickness,
      shadows: other.shadows,
      role: other.role,
      wordBreakKeepAll: other.wordBreakKeepAll,
    );
  }
}

/// Builder that resolves a [TextStyle] from a [BuildContext]. Chain
/// modifiers store style as a builder so theme tokens (`cs.primary`
/// etc.) are read at build time rather than baked in as compile-time
/// literals — mirrors Flutter `WrappedTextDataBuilder<TextStyle>`.
typedef TextStyleBuilder = TextStyle Function(BuildContext context);

/// CoUI text component.
///
/// Web-native: emits a single `<span>` whose styling is composed from
/// the token-bag [TextStyle] (Tailwind classes + inline CSS for raw
/// values). When no [style] is provided the project base typography
/// (`bodyMedium` + `onSurface` + `sans`) is applied.
///
/// Chain modifiers populate [styleBuilder] (build-time resolved) so
/// theme overrides (e.g. user-customized `ColorScheme.primary` token
/// name) are automatically picked up.
class Text extends StatelessComponent {
  /// Creates a text widget.
  const Text(
    this.data, {
    super.key,
    this.style,
    this.styleBuilder,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.semanticsLabel,
    this.textScaler,
  }) : textSpan = null;

  /// Creates a text widget with a tree of [InlineSpan] children, mirroring
  /// Flutter `Text.rich`. The root [InlineSpan] is the only thing
  /// rendered; [data] is ignored when this constructor is used.
  ///
  /// ```dart
  /// Text.rich(TextSpan(
  ///   text: 'Hello ',
  ///   children: [
  ///     TextSpan(
  ///       text: 'world',
  ///       style: TextStyle(color: 'primary', fontWeight: 'semibold'),
  ///     ),
  ///   ],
  /// ));
  /// ```
  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.styleBuilder,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.semanticsLabel,
    this.textScaler,
  }) : data = '';

  /// The literal text to display. Empty string when constructed with
  /// [Text.rich] (use [textSpan] instead).
  final String data;

  /// Optional [InlineSpan] tree rendered when constructed with
  /// [Text.rich]. `null` for the plain [Text] constructor.
  final InlineSpan? textSpan;

  /// Optional fully-resolved style override (direct construction).
  /// When both [style] and [styleBuilder] are non-null, [styleBuilder]
  /// runs first and its result is merged with [style].
  final TextStyle? style;

  /// Optional build-time style builder (chain modifiers).
  final TextStyleBuilder? styleBuilder;

  /// Whether the text should break at soft line breaks (whitespace).
  /// `false` forces single-line rendering. Mirrors Flutter
  /// `Text.softWrap` (default: `true`).
  final bool? softWrap;

  /// How visual overflow should be handled when text exceeds the
  /// container. Mirrors Flutter `Text.overflow`.
  final CoreTextOverflow? overflow;

  /// Optional max-lines clamp. Mirrors Flutter `Text.maxLines`. Renders
  /// using CSS `-webkit-line-clamp`.
  final int? maxLines;

  /// Horizontal alignment within the container. Mirrors Flutter
  /// `Text.textAlign`.
  final CoreTextAlign? textAlign;

  /// Reading direction. Mirrors Flutter `Text.textDirection`. Maps to
  /// the HTML `dir` attribute.
  final CoreTextDirection? textDirection;

  /// BCP 47 locale tag (e.g. `'ko'`, `'en-US'`). Mirrors Flutter
  /// `Text.locale` (which uses Flutter's `Locale` type). Maps to the
  /// HTML `lang` attribute.
  ///
  /// **Type difference**: Flutter SDK uses `Locale`; Web uses BCP 47
  /// string for direct `lang` attribute interop.
  final String? locale;

  /// Accessibility label override. Mirrors Flutter `Text.semanticsLabel`.
  /// Maps to the HTML `aria-label` attribute.
  final String? semanticsLabel;

  /// Text-scaling factor. Mirrors Flutter `Text.textScaler`. When set,
  /// the resolved `font-size` is multiplied by this factor before
  /// emission. `null` falls back to the browser's default zoom + the
  /// inherited scaler from any ancestor.
  ///
  /// **Type difference**: Flutter SDK uses `TextScaler`; Web uses a
  /// raw multiplier `double` (matches Flutter `TextScaler.linear` —
  /// the only Web-compatible mode).
  ///
  /// A multiplier leading follows the scaled size by itself; a role with a
  /// fixed line box (`code-*`) grows its box by the same factor, as
  /// Flutter's does — the factor rides `--coui-text-scale`, which the role
  /// class reads only for a box (`ThemeConfig`).
  final double? textScaler;

  @override
  Component build(BuildContext context) {
    // Self-apply policy is split between *parent-decided* and
    // *child-decided* properties so `Text` flows correctly when its
    // parent (Banner variant tone, Link wrapper, surface that owns
    // a typography slot like `labelLarge`) has already set a tone.
    //
    // **Parent-decided** (no self-apply, fallback to `*-inherit`):
    //   - `color`              → `text-inherit`
    //   - `font-size`          → no class emitted; CSS inherits from
    //                            the nearest ancestor that did set
    //                            one (CoUIWeb root, banner wrapper,
    //                            etc.). When a chain or `style`
    //                            *does* set it, the explicit
    //                            `text-${size}` wins.
    //   - `font-weight`        → no class emitted; same cascade as
    //                            font-size. Bold spans / chain
    //                            modifiers (`.bold`, `.semibold`)
    //                            still produce explicit `font-${w}`.
    //
    //   - `font-family`        → no class emitted; the `CoUIWeb` root
    //                            paints `font-sans` once so plain text
    //                            stays Pretendard, while a monospace
    //                            wrapper (code block, masked-input
    //                            separator) flows through to its `Text`
    //                            children — parity with Flutter's
    //                            `DefaultTextStyle` inheritance. Chain
    //                            (`.mono`, `.sans`) still wins.
    //
    // The cascade chain for the parent-decided properties starts at
    // the `CoUIWeb` root, which paints
    //   `text-${cs.onSurface} text-${CoreTextStyles.bodyMedium.name} font-sans`
    // so the default looks identical to the previous self-apply
    // behaviour for the common case. A parent that *does* set
    // `text-${CoreTextStyles.labelLarge.name}` / `text-${cs.info}` / etc. now flows
    // through naturally — that's the whole point of this split.
    //
    // **Child-decided, role-composed**: a semantic chain (`.bodyMedium`
    // etc, see `text_extension.dart`) sets `TextStyle.role` rather than
    // baking fontSize/fontWeight/height/letterSpacing as literals. That
    // emits the single `text-${role}` class, which already references
    // `var(--coui-text-${role}-size/-line-height/-weight/-tracking)` — so
    // the role stays reactive to runtime CSS-variable overrides (project
    // `theme.typography`, surface-style `[data-coui-style]` blocks) with
    // no rebuild. A primitive chained after the role (`.s14`, `.bold`,
    // `.h140`, `.letterSpacing(...)`) still sets its own raw field, which
    // lands as inline CSS and wins per-property over the role class —
    // partial overrides compose without dropping the rest of the role.
    final chainStyle = styleBuilder?.call(context);
    final effective =
        (chainStyle == null ? style : chainStyle.merge(style)) ??
        const TextStyle();

    // Tailwind classes from token fields.
    final classes = [
      if (effective.color != null)
        'text-${effective.color}'
      else
        'text-inherit',
      if (effective.backgroundColor != null) 'bg-${effective.backgroundColor}',
      if (effective.role != null) 'text-${effective.role}',
      if (effective.fontWeight != null) 'font-${effective.fontWeight}',
      if (effective.fontFamily != null) 'font-${effective.fontFamily}',
      if (effective.fontStyle == .italic) 'italic',
      if (effective.fontStyle == .normal) 'not-italic',
      if (effective.decoration != null)
        effective.decoration!.tailwindDecoration,
      if (effective.decorationColor != null)
        'decoration-${effective.decorationColor}',
      if (textAlign != null) _textAlignClass(textAlign!),
      if (softWrap == false) WebLayout.whitespaceNowrap,
    ];

    // Resolve effective font-size with optional textScaler.
    //
    // `effective.fontSize` is only non-null on an explicit primitive
    // override (`.s14`, `TextStyle(fontSize:)`) — a role (`.bodyMedium`)
    // no longer bakes it, so it stays on the `text-{role}` class /
    // ancestor cascade. With no explicit override but a role present,
    // `calc()` scales the *role's own* CSS variable in place — keeping the
    // scaled size reactive to the same theme/surface-style overrides the
    // unscaled role already gets. With neither, it scales the size the
    // text inherits: `1em` in `font-size` is the parent's computed size, so
    // the span draws what Flutter's `DefaultTextStyle` would hand the same
    // `Text` times the scaler — whatever role the ancestor painted, rather
    // than one assumed base size.
    final scaler = textScaler;
    final String? fontSizeCss;
    if (scaler != null) {
      fontSizeCss = effective.fontSize != null
          ? '${effective.fontSize! * scaler / kRemDivisor}rem'
          : effective.role != null
          ? 'calc(var(--coui-text-${effective.role}-size) * $scaler)'
          : 'calc(1em * $scaler)';
    } else {
      fontSizeCss = effective.fontSize != null
          ? '${effective.fontSize! / kRemDivisor}rem'
          : null;
    }

    // Raw values → inline CSS.
    final cssRaw = <String, String>{
      'font-size': ?fontSizeCss,
      if (scaler != null && effective.role != null)
        '--coui-text-scale': '$scaler',
      // A stated leading draws its whole-pixel box and is handed to the
      // spans inside; a size stated alone, with no role class to draw the
      // box, takes the multiplier it inherits at the new size — Flutter's
      // `DefaultTextStyle.height` reaching a `Text` that sets only its size.
      if (effective.height != null) ...{
        'line-height': CssVariableGenerator.lineHeightCss(effective.height!),
        CssVariableGenerator.leadingVar: '${effective.height}',
      } else if (fontSizeCss != null && effective.role == null)
        'line-height': CssVariableGenerator.inheritedLineHeightCss(),
      if (effective.letterSpacing != null)
        'letter-spacing': '${effective.letterSpacing}em',
      if (effective.wordSpacing != null)
        'word-spacing': '${effective.wordSpacing}em',
      if (effective.decorationStyle != null)
        'text-decoration-style': _decorationStyleCss(
          effective.decorationStyle!,
        ),
      if (effective.decorationThickness != null)
        'text-decoration-thickness':
            '${effective.decorationThickness! / kRemDivisor}rem',
      if (effective.shadows != null && effective.shadows!.isNotEmpty)
        'text-shadow': _shadowsCss(effective.shadows!),
      if (effective.wordBreakKeepAll ?? false) ..._kKeepAllCss,
      ..._overflowCss(overflow, maxLines),
    };

    final attributes = <String, String>{
      if (textDirection != null) 'dir': textDirection == .rtl ? 'rtl' : 'ltr',
      'lang': ?locale,
      'aria-label': ?semanticsLabel,
    };

    final children = textSpan == null
        ? [Component.text(data)]
        : _renderInlineSpan(textSpan!);

    return Component.element(
      tag: 'span',
      classes: classes.join(' '),
      styles: cssRaw.isEmpty ? null : Styles(raw: cssRaw),
      attributes: attributes.isEmpty ? null : attributes,
      children: children,
    );
  }
}

/// Line breaking between words only (CSS `word-break: keep-all`).
///
/// `overflow-wrap: anywhere` lets a word wider than the line break inside
/// it, the way Flutter's line breaker splits a word that cannot fit.
const Map<String, String> _kKeepAllCss = {
  'word-break': 'keep-all',
  'overflow-wrap': 'anywhere',
};

/// Renders an [InlineSpan] tree as nested `<span>` components. Each
/// span emits its own `style` (Tailwind classes + inline CSS) and
/// optional locale/aria attributes; descendants inherit unset props
/// from their nearest ancestor span (matching Flutter `TextSpan` style
/// inheritance via CSS cascade).
List<Component> _renderInlineSpan(InlineSpan span) {
  if (span is TextSpan) {
    final style = span.style;
    final classes = <String>[
      if (style?.color != null) 'text-${style!.color}',
      if (style?.backgroundColor != null) 'bg-${style!.backgroundColor}',
      if (style?.fontWeight != null) 'font-${style!.fontWeight}',
      if (style?.fontFamily != null) 'font-${style!.fontFamily}',
      if (style?.fontStyle == .italic) 'italic',
      if (style?.fontStyle == .normal) 'not-italic',
      if (style?.decoration != null) style!.decoration!.tailwindDecoration,
      if (style?.decorationColor != null)
        'decoration-${style!.decorationColor}',
    ];
    final cssRaw = <String, String>{
      if (style?.fontSize != null)
        'font-size': '${style!.fontSize! / kRemDivisor}rem',
      // Same rule as the root span: a stated leading draws and hands down
      // its box, a size stated alone reads the inherited multiplier.
      if (style?.height != null) ...{
        'line-height': CssVariableGenerator.lineHeightCss(style!.height!),
        CssVariableGenerator.leadingVar: '${style.height}',
      } else if (style?.fontSize != null)
        'line-height': CssVariableGenerator.inheritedLineHeightCss(),
      if (style?.letterSpacing != null)
        'letter-spacing': '${style!.letterSpacing}em',
      if (style?.wordSpacing != null) 'word-spacing': '${style!.wordSpacing}em',
      if (style?.decorationStyle != null)
        'text-decoration-style': _decorationStyleCss(style!.decorationStyle!),
      if (style?.decorationThickness != null)
        'text-decoration-thickness':
            '${style!.decorationThickness! / kRemDivisor}rem',
      if (style?.shadows != null && style!.shadows!.isNotEmpty)
        'text-shadow': _shadowsCss(style.shadows!),
    };
    final attributes = <String, String>{
      'lang': ?span.locale,
      'aria-label': ?span.semanticsLabel,
    };
    final children = <Component>[
      if (span.text != null) Component.text(span.text!),
      if (span.children != null)
        for (final child in span.children!) ..._renderInlineSpan(child),
    ];
    final hasStyle = classes.isNotEmpty || cssRaw.isNotEmpty;
    final hasAttrs = attributes.isNotEmpty;
    if (!hasStyle && !hasAttrs) {
      // No-op span — return children directly.
      return children;
    }
    return [
      Component.element(
        tag: 'span',
        classes: classes.isEmpty ? null : classes.join(' '),
        styles: cssRaw.isEmpty ? null : Styles(raw: cssRaw),
        attributes: hasAttrs ? attributes : null,
        children: children,
      ),
    ];
  }
  // Future: WidgetSpan-like inline component embedding.
  return const [];
}

/// Maps `CoreTextAlign` enum → Tailwind `text-{align}` utility.
String _textAlignClass(CoreTextAlign a) {
  return switch (a) {
    .start => 'text-start',
    .end => 'text-end',
    .center => 'text-center',
    .justify => 'text-justify',
    .left => 'text-left',
    .right => 'text-right',
  };
}

/// Maps `CoreTextDecorationStyle` enum → CSS `text-decoration-style` value.
String _decorationStyleCss(CoreTextDecorationStyle s) {
  return switch (s) {
    .solid => 'solid',
    .double => 'double',
    .dotted => 'dotted',
    .dashed => 'dashed',
    .wavy => 'wavy',
  };
}

/// Renders a list of [Shadow] descriptors as a comma-separated CSS
/// `text-shadow` value. Color tokens are wrapped via the same
/// `--coui-${token}` CSS variable convention used elsewhere; null
/// colors fall through to `currentColor` so the shadow inherits text
/// color (matches Flutter `Shadow(color: null)` default behaviour).
String _shadowsCss(List<Shadow> shadows) {
  return shadows
      .map((shadow) {
        final colorCss = shadow.color == null
            ? 'currentColor'
            // Wrap the bare `R G B` triplet var in `rgb()` so the
            // text-shadow colour is valid; un-wrapped it is dropped
            // (token-coloured text shadows silently fail). Same as #2122.
            : 'rgb(var(--coui-${shadow.color}))';
        return '${shadow.offset.dx}px ${shadow.offset.dy}px '
            '${shadow.blurRadius}px $colorCss';
      })
      .join(', ');
}

/// Maps `softWrap` / `overflow` / `maxLines` → CSS rules.
///
/// - `maxLines` non-null: `-webkit-line-clamp` (works for ellipsis +
///   visible variants by combining with `text-overflow`).
/// - `overflow == ellipsis`: needs `overflow: hidden` + `text-overflow:
///   ellipsis` for single-line truncation. With `maxLines` it's
///   line-clamp instead.
/// - `overflow == clip`: `overflow: hidden`.
/// - `overflow == fade` / `visible`: not directly representable in CSS;
///   fall back to clip + visible respectively for sensible defaults.
Map<String, String> _overflowCss(
  CoreTextOverflow? overflow,
  int? maxLines,
) {
  final css = <String, String>{};
  if (maxLines != null) {
    css['display'] = '-webkit-box';
    css['-webkit-box-orient'] = 'vertical';
    css['-webkit-line-clamp'] = '$maxLines';
    css['overflow'] = WebLayout.hidden;
    if (overflow == .ellipsis || overflow == null) {
      css['text-overflow'] = 'ellipsis';
    }
    return css;
  }
  switch (overflow) {
    case .ellipsis:
      css['overflow'] = WebLayout.hidden;
      css['text-overflow'] = 'ellipsis';
      css['white-space'] = 'nowrap';
    // True fade requires a gradient mask tied to the container's
    // background, so clip is used as a sensible CSS approximation.
    case .clip || .fade:
      css['overflow'] = WebLayout.hidden;
    case .visible:
      css['overflow'] = 'visible';
    case null:
      break;
  }
  return css;
}
