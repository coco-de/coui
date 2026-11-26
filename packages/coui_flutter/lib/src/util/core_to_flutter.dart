/// Conversion utilities from CoUI core platform-neutral types
/// to Flutter framework primitives — the single Core→Flutter EMIT file.
///
/// Domain types expose `.toValue()` here (returning `Color`,
/// `EdgeInsets`, `BorderRadius`, `TextStyle`, `BoxShadow`, `Curve`, …) —
/// the convention is a single `.toValue()` whenever a Core type maps to
/// one Flutter target. Intent verbs (`.toXxx()`) are reserved for the few
/// cases where one Core type fans out to several Flutter types (e.g.
/// `CoreVerticalAlign.toTextAlignVertical()` /
/// `.toCrossAxisAlignment()`). The typography helpers
/// (`resolveTypographyRole`, `applyCoreTextStyle`) resolve token roles
/// through the active theme. The Web side mirrors this in
/// `coui_web/lib/src/util/core_to_css.dart`, returning CSS strings
/// instead.
library;

import 'dart:ui' show ColorSpace;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/stacks/stacks_style.dart'
    show coreAlignmentToFlutter;
import 'package:coui_flutter/src/theme/theme.dart' show ThemeData;
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show CrossAxisAlignment;
import 'package:flutter/semantics.dart' show SemanticsRole;

/// Maps a `coui_core` numeric font weight ([CoreTextStyle.fontWeight] —
/// an `int` such as `400` / `600`) to the matching Flutter [FontWeight].
///
/// Returns `null` when [value] is `null` so callers can forward an
/// optional weight without a separate null branch. A non-null value with
/// no matching enum entry falls back to [orElse] (default
/// [FontWeight.normal]).
///
/// Single weight-mapping site for the whole package — resolvers and the
/// `CoreTextStyle` merge helpers all route through here instead of
/// re-inlining `FontWeight.values.firstWhere(...)`.
FontWeight? fontWeightFromInt(int? value, {FontWeight orElse = .normal}) {
  if (value == null) {
    return null;
  }
  return FontWeight.values.firstWhere(
    (w) => w.value == value,
    orElse: () => orElse,
  );
}

/// CoreColor → Flutter `Color`.
extension CoreColorToFlutter on CoreColor {
  /// Returns the Flutter `Color` resolved from this descriptor.
  ///
  /// Raw ARGB colours and tagged tokens (e.g. `scheme.primary.toValue()`)
  /// return directly. Unresolved token references resolve against
  /// [CoreThemePresets.lightColorScheme] (the designer light palette) so that
  /// `const ThemeData(colorScheme: CoreColorScheme.tokenized())` still
  /// renders sensible defaults without any scheme override.
  Color toValue() {
    if (!isResolved) {
      final resolved = CoreThemePresets.lightColorScheme.resolve(this);
      if (resolved.isResolved) {
        return Color(resolved.argb).withValues(alpha: opacity);
      }
      throw StateError(
        'CoreColor.toValue called on unresolved token "${token!.name}". '
        'Pass the colour through a * component or call '
        'scheme.resolve(color) before converting.',
      );
    }
    // Multiply the source ARGB's alpha by the opacity modifier — raw
    // transparent fills (e.g. `kTransparent = CoreColor(0x00000000)`)
    // must stay transparent in Flutter; the previous
    // `.withValues(alpha: opacity)` would force fully-opaque black.
    final base = Color(argb);
    final combinedAlpha = (base.a * opacity).clamp(0.0, 1.0);
    return base.withValues(alpha: combinedAlpha);
  }

  /// Flutter-side compatibility shim — equivalent to
  /// `toValue().withValues(...)`. Lets call sites that previously held a
  /// `Color` keep working when `theme.colorScheme.X` now returns
  /// [CoreColor].
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
    ColorSpace? colorSpace,
  }) => toValue().withValues(
    alpha: alpha,
    red: red,
    green: green,
    blue: blue,
    colorSpace: colorSpace,
  );

  /// Flutter-side compatibility shim — equivalent to
  /// `toValue().toARGB32()`.
  int toARGB32() => toValue().toARGB32();

  /// Flutter-side compatibility shim — equivalent to
  /// `toValue().computeLuminance()`.
  double computeLuminance() => toValue().computeLuminance();
}

/// Implicit nullable resolution — `theme.colorScheme.onSurface.toValue()` (a
/// nullable [CoreColor]) is commonly used with `!` to coerce non-null.
/// Provide `toValue()` on `CoreColor?` so call sites can write
/// `theme.colorScheme.onSurface?.toValue()`.
extension NullableCoreColorToFlutter on CoreColor? {
  /// Resolves the colour or returns `null` when this descriptor is null.
  Color? toValue() => this?.toValue();
}

/// CoreGradient → Flutter `Gradient`.
extension CoreGradientToFlutter on CoreGradient {
  /// Returns the paint-ready [LinearGradient] / [RadialGradient].
  ///
  /// Every stop colour runs through `scheme.resolve(c).toValue()`, so token
  /// stops track the active scheme (light / dark) and raw ARGB stops pass
  /// through untouched. [alphaScale] multiplies every stop's own alpha — a
  /// surface that is translucent as a whole (`surfaceOpacity`) dims a
  /// gradient fill stop by stop, the way it dims a solid one.
  ///
  /// A radial gradient is centred on the box it paints and reaches half its
  /// shorter side (Flutter's default centre and `radius` of `0.5` — CSS
  /// `radial-gradient(circle closest-side at 50% 50%)`); [begin] is ignored,
  /// as the contract states.
  Gradient toValue({
    required CoreColorScheme scheme,
    double alphaScale = 1,
  }) {
    final resolved = [
      for (final c in colors)
        scheme
            .resolve(alphaScale == 1 ? c : c.scaleAlpha(alphaScale))
            .toValue(),
    ];
    switch (type) {
      case .linear:
        return LinearGradient(
          begin: coreAlignmentToFlutter(begin),
          end: coreAlignmentToFlutter(end),
          colors: resolved,
          stops: stops,
        );
      case .radial:
        return RadialGradient(colors: resolved, stops: stops);
    }
  }
}

/// CoreVectorGlyph → Flutter `Path`.
extension CoreVectorGlyphToFlutter on CoreVectorGlyph {
  /// Returns the drawing as a [Path] scaled from the glyph's own box to
  /// [size] and filled by the glyph's fill rule.
  ///
  /// The path syntax is the four-command grammar `CoreVectorGlyph.path`
  /// states — absolute `M` / `L` / `C` / `Z`, every number separated by one
  /// space — so a parser for exactly those commands is all this needs.
  /// Anything else throws a [FormatException]: a drawing that grew a fifth
  /// command is a change to the contract, not something to skip quietly.
  Path toPath(Size size) {
    final scaleX = width == 0 ? 0.0 : size.width / width;
    final scaleY = height == 0 ? 0.0 : size.height / height;
    final out = Path()
      ..fillType = switch (fillRule) {
        .evenOdd => .evenOdd,
        .nonZero => .nonZero,
      };
    final tokens = path.trim().split(' ');
    var i = 0;
    double x() => double.parse(tokens[i++]) * scaleX;
    double y() => double.parse(tokens[i++]) * scaleY;
    while (i < tokens.length) {
      final command = tokens[i++];
      switch (command) {
        case 'M':
          out.moveTo(x(), y());
        case 'L':
          out.lineTo(x(), y());
        case 'C':
          out.cubicTo(x(), y(), x(), y(), x(), y());
        case 'Z':
          out.close();
        default:
          throw FormatException('Unsupported path command "$command"', path);
      }
    }
    return out;
  }
}

/// CoreEdgeInsets → Flutter `EdgeInsets`.
///
/// Both conversions take the theme's [CoreSurfaceGeometryConstraint] and
/// move every side through its density (`geometry.insets`) before
/// converting — one rung on the spacing scale. Flutter has no runtime
/// indirection between a resolver and painted padding, so the conversion is
/// the only place a density can reach an inset.
///
/// `geometry` is optional here, unlike the radius conversion beside it,
/// because this extension is public API that apps call on their own
/// values, and a required parameter would break every such call without
/// the deprecation window `process/deprecation.md` requires. A caller that
/// passes none gets the authored values. Inside this repository passing it
/// is not optional: the `pass_theme_geometry` lint (`coui_lints`) reports
/// every call that leaves it out, so "someone forgot" is a CI failure
/// rather than a padding that silently ignores the density.
extension CoreEdgeInsetsToFlutter on CoreEdgeInsets {
  /// Returns Flutter `EdgeInsets` with sides preserved, after [geometry]'s
  /// density has moved them.
  ///
  /// Throws on a directional value rather than flattening it. Flattening
  /// would render correctly in a left-to-right locale and be wrong in a
  /// right-to-left one, with nothing to see in between — the failure
  /// shape this repository keeps paying for. Use [toGeometry] for a value
  /// that may be either.
  ///
  /// Pass `Theme.of(context).geometry`; it is already in scope in almost
  /// every resolver. Without it the authored sides are returned unmoved.
  EdgeInsets toValue({CoreSurfaceGeometryConstraint? geometry}) {
    if (isDirectional) {
      throw ArgumentError(
        'Directional insets cannot become EdgeInsets — start and end have '
        'no fixed side. Use toGeometry().',
      );
    }

    final bent = geometry?.insets(this) ?? this;

    return EdgeInsets.fromLTRB(bent.left, bent.top, bent.right, bent.bottom);
  }

  /// Returns Flutter insets, resolving start and end when the value is
  /// directional, after [geometry]'s density has moved every side.
  ///
  /// `EdgeInsetsDirectional` resolves against the ambient text direction,
  /// so the same value indents from the left in English and from the
  /// right in Arabic without the component knowing which locale it is in.
  /// The density keeps that: `geometry.insets` moves start and end and
  /// leaves them start and end.
  ///
  /// The return type is the widest of the two forms. Kept separate from
  /// [toValue] so the hundreds of resolvers whose padding is symmetric —
  /// and therefore direction-invariant — keep the narrower type they
  /// already have.
  ///
  /// Pass `Theme.of(context).geometry`; without it the authored sides are
  /// returned unmoved.
  EdgeInsetsGeometry toGeometry({CoreSurfaceGeometryConstraint? geometry}) {
    final bent = geometry?.insets(this) ?? this;

    return bent.isDirectional
        ? EdgeInsetsDirectional.fromSTEB(
            bent.start,
            bent.top,
            bent.end,
            bent.bottom,
          )
        : EdgeInsets.fromLTRB(bent.left, bent.top, bent.right, bent.bottom);
  }
}

/// CoreBorderRadius → Flutter `BorderRadius`.
extension CoreBorderRadiusToFlutter on CoreBorderRadius {
  /// Returns Flutter `BorderRadius` with the four corner radii, after the
  /// active surface style has had its say.
  ///
  /// [geometry] is required rather than defaulted on purpose. Flutter has
  /// no runtime indirection between a resolver and a painted corner — no
  /// equivalent of the CSS variable the Web side re-points — so the only
  /// place a style can reach a radius is right here, at the conversion.
  /// A default would make adoption opt-in, and this repository has twice
  /// shipped a geometry axis that was declared, wired through equality,
  /// and then read by nobody. Requiring it turns "someone forgot" into a
  /// compile error.
  ///
  /// Pass `Theme.of(context).geometry`; it is already in scope in almost
  /// every resolver.
  BorderRadius toValue({required CoreSurfaceGeometryConstraint geometry}) {
    final bent = geometry.borderRadius(this);

    return .only(
      topLeft: .circular(bent.topLeft),
      topRight: .circular(bent.topRight),
      bottomLeft: .circular(bent.bottomLeft),
      bottomRight: .circular(bent.bottomRight),
    );
  }
}

/// CSS `box-shadow` blur radius → the Flutter [BoxShadow.blurRadius]
/// that paints the **same Gaussian σ**.
///
/// `CoreShadowLayer.blurRadius` carries the CSS convention (the spec
/// defines σ = radius / 2), but Flutter's engine derives
/// σ = radius × 0.57735 + 0.5 (Skia's `ConvertRadiusToSigma`, see
/// `dart:ui` `Shadow.blurSigma`). Forwarding the CSS value unconverted
/// paints every shadow wider and darker than its Web class mirror
/// (`shadow-md` 등) — blur 6 renders σ 3.96 instead of the intended 3.0.
/// Inverting the Skia mapping restores σ-parity; radii whose CSS σ is
/// at or below Skia's 0.5 intercept clamp to 0 (effectively sharp,
/// which is what a sub-pixel σ reads as anyway).
double cssBlurRadiusToFlutter(double cssBlurRadius) {
  final sigma = cssBlurRadius / 2;
  final radius = (sigma - 0.5) / 0.57735;
  return radius > 0 ? radius : 0;
}

/// Figma layer-blur radius → the Gaussian σ that `ImageFilter.blur` takes.
///
/// A Figma layer blur states its radius as twice the standard deviation
/// (the way a CSS `box-shadow` blur does, and the way Figma's own CSS export
/// writes `blur(radius / 2)`), while `ImageFilter.blur` takes σ itself — so
/// forwarding the Figma number unconverted would blur twice as wide as the
/// canvas. The Web mirror is the CSS `filter: blur()` length, which is the
/// same σ.
double figmaLayerBlurToSigma(double radius) => radius / 2;

/// The dimming a material applies, resolved for one theme's mode.
///
/// The authored value is a pair — [CoreBackdropBrightness] carries the
/// argument for why one number cannot say it — and this is the single
/// place on this platform where it becomes the scalar a renderer takes.
///
/// An extension rather than thirteen inline ternaries: every resolver that
/// paints a material needs this, the theme is already in scope at each of
/// them, and the `Brightness` → [CoreBrightness] hop is exactly the kind of
/// (type × direction) conversion `code-style/conversion-helpers.md` says
/// belongs in one function in this file. Resolvers are not branching on the
/// axis by calling it; they are asking the theme what its own mode resolved
/// to, which is what they already do for every colour.
extension CoreSurfaceTokenBrightnessIn on CoreSurfaceToken {
  /// This material's backdrop multiplier under [theme].
  double backdropBrightnessIn(ThemeData theme) =>
      backdropBrightness.resolve(theme.coreBrightness);
}

/// The fill share a material applies, resolved for one theme's mode.
///
/// The same hop as [CoreSurfaceTokenBrightnessIn] for the same reason, and
/// kept as its own extension so each name says which term it resolves. The
/// authored value is a pair — [CoreSurfaceOpacity] carries the argument for
/// why one number cannot say it — and every resolver that paints a
/// material's fill reads it through here. There is deliberately no scalar
/// getter on the token itself: a reader that could skip the mode is a
/// reader that draws the light fill under a dark palette.
extension CoreSurfaceTokenOpacityIn on CoreSurfaceToken {
  /// This material's fill share under [theme].
  double opacityIn(ThemeData theme) => opacity.resolve(theme.coreBrightness);
}

/// The backdrop pass's colour scalars → the 5×4 matrix that applies them.
///
/// One matrix rather than two composed filters, because the surface's
/// chroma lift and its dimming are one pass. Composing them would cost a
/// second render pass to compute a product this multiplies out for free.
///
/// [saturation] — `1.0` returns identity. Above it, chroma is pushed away
/// from the pixel's own luminance; below it, toward it, with `0.0` landing
/// on greyscale.
///
/// The coefficients are Rec. 709 luminance weights, which is what makes
/// this the *same* operation as the Web side's `saturate()` rather than
/// merely a similar-looking one — CSS defines that function by the SVG
/// `feColorMatrix type="saturate"` matrix, and this is that matrix. A
/// hand-rolled approximation here would drift from the Web twin by an
/// amount that only shows when the two are held side by side.
///
/// [brightness] — `1.0` returns identity; below it the pixel is scaled
/// toward black. CSS `brightness()` is a linear transfer with that slope
/// and no intercept, so it is a plain multiply here too.
///
/// ## Order is part of the answer
///
/// The dimming is applied **after** the chroma lift, matching the Web's
/// `saturate(s) brightness(b)` filter list — CSS filter functions run
/// left to right. Since scaling all three channels commutes with nothing
/// in the saturation matrix's cross terms, swapping the two produces
/// different pixels rather than the same ones in a different order.
///
/// Multiplying `diag(b, b, b, 1)` on the left of the saturation matrix is
/// exactly "scale the three colour rows by `b`", which is what this does
/// — the alpha row is untouched because brightness does not act on it.
List<double> backdropColorMatrix({
  required double saturation,
  required double brightness,
}) {
  const lumR = 0.213;
  const lumG = 0.715;
  const lumB = 0.072;

  final invR = lumR * (1 - saturation);
  final invG = lumG * (1 - saturation);
  final invB = lumB * (1 - saturation);

  final b = brightness;

  return <double>[
    (invR + saturation) * b, invG * b, invB * b, 0, 0, //
    invR * b, (invG + saturation) * b, invB * b, 0, 0, //
    invR * b, invG * b, (invB + saturation) * b, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

/// The frost's colour matrix: colour untouched, alpha scaled to [opacity].
///
/// Composed over a Gaussian and handed to a backdrop pass, it is the cloud
/// at its share. The pass composites its result over the backdrop it read, so
/// what lands is `opacity · cloud + (1 − opacity) · backdrop` per channel —
/// `CoreSurfaceFrost.mix` — without a shader, which is what lets the frost
/// run on every engine the plain blur does.
List<double> surfaceFrostColorMatrix(double opacity) => <double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, opacity, 0, //
];

/// `CoreShadowLayer` → Flutter `BoxShadow`.
extension CoreShadowLayerToFlutter on CoreShadowLayer {
  /// Converts this layer to a [BoxShadow] using [shadowColor] tinted by
  /// the layer's `opacity`.
  ///
  /// The CSS-convention `blurRadius` is converted through
  /// [cssBlurRadiusToFlutter] so the painted Gaussian σ matches the Web
  /// mirror exactly.
  ///
  /// `inset` layers are mapped to [BlurStyle.inner]. Note that Flutter's
  /// inner blur is rendered as an inner shadow on the box edge, which is
  /// close to but not identical to CSS `box-shadow: inset`. For pixel-exact
  /// inset rendering use a custom painter.
  ///
  /// [scale] multiplies every dimensional field (both offsets, the blur and
  /// the spread) for a resolver whose surface scales its geometry with
  /// `theme.scaling`. The CSS blur radius is scaled *before* the σ
  /// conversion, so a scaled layer still paints the Gaussian the Web mirror
  /// would paint at that size. The default `1` leaves every value as
  /// authored.
  BoxShadow toValue(Color shadowColor, {double scale = 1}) => .new(
    color: shadowColor.withValues(alpha: shadowColor.a * opacity),
    offset: Offset(offsetX * scale, offsetY * scale),
    blurRadius: cssBlurRadiusToFlutter(blurRadius * scale),
    spreadRadius: spreadRadius * scale,
    blurStyle: inset ? .inner : .normal,
  );
}

/// `List<CoreShadowLayer>` → Flutter `List<BoxShadow>`.
///
/// `base` supplies the base color (typically
/// `theme.colorScheme.onSurface.toValue()` or similar) — each layer applies
/// its `opacity` to that base.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: CoreShadow.md.toValue(base: colorScheme.shadow.toValue()),
///   ),
/// )
/// ```
extension CoreShadowLayersToFlutter on List<CoreShadowLayer> {
  /// Converts every layer to a [BoxShadow] tinted by [base], after the
  /// active surface style has had its say.
  ///
  /// [geometry] is required for the same reason the radius conversion
  /// requires it: this is the only point a style can reach a shadow on
  /// this platform, and a defaulted parameter would make adoption opt-in.
  /// Pass `Theme.of(context).geometry`.
  ///
  /// [scale] is forwarded to every layer — see
  /// [CoreShadowLayerToFlutter.toValue]. It applies after the style's
  /// transform, so the style bends what the component authored and the
  /// resolver's scaling sizes the result.
  List<BoxShadow> toValue({
    required Color base,
    required CoreSurfaceGeometryConstraint geometry,
    double scale = 1,
  }) =>
      geometry.shadow(this).map((l) => l.toValue(base, scale: scale)).toList();
}

/// `CoreOutlinedContainerElevation` → Flutter `List<BoxShadow>`.
///
/// Every component whose surface is a `OutlinedContainer`
/// (`Card`, `Frame`, picker panels …) reads elevation through this
/// enum, so the Flutter `BoxShadow` mapping lives here (shared adapter)
/// rather than in any per-component `*_style.dart` resolver — the Web
/// mirror is `CoreOutlinedContainerElevationTailwind.tailwindShadowClass`
/// in `core_to_css.dart`.
///
/// The geometry aliases the designer `CoreShadow.sm/md/lg` scale — the
/// same tokens the Web `shadow-{sm|md|lg}` classes resolve to via the
/// `--shadow-*` CSS variables — through
/// [CoreOutlinedContainerStyle.defaultSoftShadow] /
/// [CoreOutlinedContainerStyle.defaultMediumShadow] /
/// [CoreOutlinedContainerStyle.defaultStrongShadow], so Flutter and Web
/// paint the identical stack from a single source of truth.
extension CoreOutlinedContainerElevationShadow
    on CoreOutlinedContainerElevation {
  /// The stack this elevation names, before any conversion.
  ///
  /// Exposed because an inset layer and an outer layer are painted by
  /// different machinery, and Flutter's `BoxShadow` carries no inset
  /// flag — a caller that needs to tell them apart has to do it here,
  /// while the Core records still say which is which.
  List<CoreShadowLayer> get layers {
    switch (this) {
      case .none:
        return const [];
      case .soft:
        return CoreOutlinedContainerStyle.defaultSoftShadow;
      case .medium:
        return CoreOutlinedContainerStyle.defaultMediumShadow;
      case .strong:
        return CoreOutlinedContainerStyle.defaultStrongShadow;
    }
  }

  /// Returns the [BoxShadow] stack for this elevation, tinted by
  /// [base]. `none` returns an empty list.
  ///
  /// Each layer's `opacity` (alpha) is baked into the [CoreShadowLayer]
  /// records on [CoreOutlinedContainerStyle], so the adapter just
  /// forwards via [CoreShadowLayersToFlutter.toValue].
  List<BoxShadow> toValue({
    required Color base,
    required CoreSurfaceGeometryConstraint geometry,
  }) {
    switch (this) {
      case .none:
        return const [];
      case .soft:
        return CoreOutlinedContainerStyle.defaultSoftShadow.toValue(
          base: base,
          geometry: geometry,
        );
      case .medium:
        return CoreOutlinedContainerStyle.defaultMediumShadow.toValue(
          base: base,
          geometry: geometry,
        );
      case .strong:
        return CoreOutlinedContainerStyle.defaultStrongShadow.toValue(
          base: base,
          geometry: geometry,
        );
    }
  }
}

/// CoreClipMode → Flutter `Clip`.
/// CoreAxis → Flutter `Axis`.
///
/// One converter for one (Core type × direction), per
/// `code-style/conversion-helpers.md`. This landed here after the same
/// two-line body had been copied into three widgets independently
/// (`star_rating`, `card_image`, `dot_indicator`) — a conversion with three
/// homes is three places to forget when the enum grows a member.
extension CoreAxisToFlutter on CoreAxis {
  /// Returns the Flutter `Axis` equivalent.
  Axis toValue() => switch (this) {
    .horizontal => .horizontal,
    .vertical => .vertical,
  };
}

/// `CoreClipMode` → Flutter `Clip`.
extension CoreClipModeToFlutter on CoreClipMode {
  /// Returns Flutter `Clip` equivalent.
  Clip toValue() => switch (this) {
    .none => .none,
    .hardEdge => .hardEdge,
    .antiAlias => .antiAlias,
    .antiAliasWithSaveLayer => .antiAliasWithSaveLayer,
  };
}

/// CoreMarqueeCurve → Flutter `Curve`.
extension CoreMarqueeCurveToFlutter on CoreMarqueeCurve {
  /// Returns Flutter `Curve` equivalent.
  Curve toValue() => switch (this) {
    .linear => Curves.linear,
    .easeIn => Curves.easeIn,
    .easeOut => Curves.easeOut,
    .easeInOut => Curves.easeInOut,
  };
}

/// `CoreTextAlign` → Flutter `TextAlign`.
extension CoreTextAlignToFlutter on CoreTextAlign {
  /// Returns the matching Flutter `TextAlign` enum.
  TextAlign toValue() => switch (this) {
    .start => .start,
    .end => .end,
    .center => .center,
    .justify => .justify,
    .left => .left,
    .right => .right,
  };
}

/// `CoreTextDecoration` → Flutter `TextDecoration`.
extension CoreTextDecorationToFlutter on CoreTextDecoration {
  /// Returns the matching Flutter `TextDecoration`.
  TextDecoration toValue() => switch (this) {
    .none => .none,
    .underline => .underline,
    .overline => .overline,
    .lineThrough => .lineThrough,
  };
}

/// `CoreTextOverflow` → Flutter `TextOverflow`.
extension CoreTextOverflowToFlutter on CoreTextOverflow {
  /// Returns the matching Flutter `TextOverflow` enum.
  TextOverflow toValue() => switch (this) {
    .clip => .clip,
    .fade => .fade,
    .ellipsis => .ellipsis,
    .visible => .visible,
  };
}

/// `CoreVerticalAlign` → Flutter `TextAlignVertical`.
extension CoreVerticalAlignToTextAlignVertical on CoreVerticalAlign {
  /// Returns the matching Flutter `TextAlignVertical`.
  TextAlignVertical toTextAlignVertical() => switch (this) {
    .top => .top,
    .center => .center,
    .bottom => .bottom,
  };

  /// Returns the matching Flutter `CrossAxisAlignment` for `Row` /
  /// `Column` layouts.
  CrossAxisAlignment toCrossAxisAlignment() => switch (this) {
    .top => .start,
    .center => .center,
    .bottom => .end,
  };
}

/// `CoreTextStyle` → Flutter `TextStyle`.
///
/// The single Core→Flutter typography emit, with two modes selected by
/// whether a [ThemeData] is supplied:
///
/// - **`toValue(theme: theme)`** — full theme-aware conversion. A
///   (possibly token-backed, possibly merged) `CoreTextStyle` is
///   materialised against the active theme: token roles are resolved
///   through `theme.typography`, the colour is resolved through the
///   active scheme so dark mode tracks, and `em` letter spacing is
///   converted to logical px. This is the canonical path — it folds
///   together what `resolveTypographyRole` (token → slot) and
///   `applyCoreTextStyle` (scheme-resolved colour + em→px) did
///   separately.
/// - **`toValue()` / `toValue(color: ...)`** — legacy value-only
///   conversion. Token resolution must already have happened via
///   `typography.resolve(...)`; a non-null [token] throws.
///
/// `letterSpacing` is stored on `CoreTextStyle` as an `em` ratio (so
/// `CoreLetterSpacing.tight = -0.025` means -0.025 em). Flutter's
/// `TextStyle.letterSpacing` is logical pixels, so the ratio is
/// multiplied by `fontSize` here. If `fontSize` is null, letter
/// spacing is left null (Flutter inherits parent).
///
/// A fixed line box (`lineHeightPx`, the code roles' 21px) wins over the
/// `lineHeight` multiplier. Flutter's `TextStyle.height` is itself a
/// multiplier, so the box is drawn as `height = lineHeightPx / fontSize`
/// against the final font size. Every conversion below shares that one
/// rule, so the box cannot be drawn one way here and another way there.
extension CoreTextStyleToFlutter on CoreTextStyle {
  /// Returns the Flutter `TextStyle` materialised from this descriptor.
  ///
  /// When [theme] is non-null, performs the full theme-aware resolution:
  /// - **token-backed role** (`CoreTextStyle.token(CoreTextStyles.X)`):
  ///   the slot is materialised via `theme.typography.resolve(...)`.
  /// - **merged style** (`default.merge(override)` — a token plus overlay
  ///   fields populated at once): the slot is materialised first, then
  ///   the overlay's non-null raw fields win over the slot.
  /// - **already-materialised style** (`token == null`): used as-is.
  ///
  /// In every theme-aware case the colour is resolved through the active
  /// scheme (`theme.colorScheme.resolve(color).toValue()`) so dark mode
  /// tracks. A [color] override, when supplied, takes precedence over
  /// this style's own resolved `color`.
  ///
  /// When [theme] is null, behaves as the legacy value-only conversion:
  /// throws `StateError` if [token] is non-null (the token must be
  /// resolved through `theme.typography.resolve(this)` first so the
  /// slot's `fontSize` / `fontWeight` / `lineHeight` / `letterSpacing`
  /// are populated). A [color] override, when supplied, takes precedence
  /// over this style's own `color` field; resolvers pass the
  /// already-resolved foreground colour (after
  /// `scheme.resolve(...).toValue()`).
  TextStyle toValue({Color? color, ThemeData? theme}) {
    if (theme != null) {
      // Materialise the token slot when present, then overlay this
      // style's own non-null raw fields so caller overrides (e.g. a
      // `fontWeight` merged onto a token role) win. `typography.resolve`
      // only overlays `color` onto the slot, so for a merged style
      // (token + overlay fields) the remaining overlay fields are
      // re-applied here: a token-stripped copy of this style is merged
      // onto the slot so every populated overlay field — including
      // `color` — wins.
      //
      // The merge also settles the line box: an overlay that states a
      // multiplier but no box drops the slot's box, so the newer
      // statement is the one drawn.
      final materialised = token == null
          ? this
          : theme.typography
                .resolve(CoreTextStyle.token(token!))
                .merge(_rawFields);

      final fs = materialised.fontSize;
      final ls = materialised.letterSpacing;
      final ownColor = materialised.color;
      return TextStyle(
        color:
            color ??
            (ownColor == null
                ? null
                : theme.colorScheme.resolve(ownColor).toValue()),
        fontSize: fs,
        fontWeight: fontWeightFromInt(materialised.fontWeight),
        letterSpacing: ls == null || fs == null ? null : ls * fs,
        height: _heightOf(materialised),
        // CSS line-height mirror: the Web side distributes the extra
        // leading half above / half below the glyphs (half-leading),
        // while Flutter's default `proportional` splits it by the
        // font's ascent/descent ratio — glyphs sit visibly below the
        // line-box centre for every CoUI role that carries a line
        // height (bodyMedium 1.5, the code roles' fixed 21px box 등).
        // `even` is the exact CSS behaviour, so inherited and explicit
        // CoUI text centres identically on both platforms.
        leadingDistribution: .even,
        // Pin the CoUI font stack when the style names no family — an
        // inherited family would otherwise come from whatever ambient
        // DefaultTextStyle wins (e.g. MaterialApp's Roboto typography),
        // splitting glyph shapes from the Web side (the required-marker
        // `*` rendered with Roboto's 5 spokes while Web drew
        // Pretendard's 6).
        fontFamily: materialised.fontFamily ?? CoreFontFamily.sans,
        fontFamilyFallback: _fallbackFor(materialised.fontFamily),
      );
    }

    if (token != null) {
      throw StateError(
        'CoreTextStyle.toValue() called on an unresolved token-backed '
        'instance (token: "${token!.name}"). Call '
        'theme.typography.resolve(textStyle) first to materialise '
        'the slot, then convert — or pass `theme:` to resolve in one '
        'step.',
      );
    }
    final fs = fontSize;
    final ls = letterSpacing;
    final ownColor = this.color;
    return TextStyle(
      color: color ?? ownColor?.toValue(),
      fontSize: fs,
      fontWeight: fontWeightFromInt(fontWeight),
      letterSpacing: ls == null || fs == null ? null : ls * fs,
      height: _heightOf(this),
      // CSS half-leading mirror — see the themed branch above.
      leadingDistribution: .even,
      fontFamily: fontFamily,
      // An unnamed family inherits, fallbacks included — only a named one
      // brings its own.
      fontFamilyFallback: fontFamily == null ? null : _fallbackFor(fontFamily),
    );
  }

  /// Returns only the explicitly-set overlay fields as a partial Flutter
  /// `TextStyle`, ignoring the typography role [token].
  ///
  /// The Flutter twin of the Web `toInlineCss()` bundle: a role names a
  /// whole type ramp, and text that flows inside someone else's
  /// paragraph (an inline link in a table cell or a heading) must take
  /// that ramp from its surroundings instead. Every field this style
  /// leaves null stays null here, so a `TextSpan` carrying the result
  /// inherits size / weight / leading from its parent span.
  ///
  /// [color], when supplied, wins over this style's own colour — pass the
  /// scheme-resolved foreground, since this conversion has no theme to
  /// resolve a colour token against.
  ///
  /// `letterSpacing` is an em ratio and Flutter's is logical px, so it
  /// only converts when [fontSize] is set here too; without it the ratio
  /// has no size to multiply and the inherited tracking is kept. A fixed
  /// line box (`lineHeightPx`) is the same: Flutter's `height` divides it
  /// by the font size, so without [fontSize] here the inherited height is
  /// kept.
  TextStyle toOverlayValue({Color? color}) {
    return _rawFields.toValue(color: color);
  }

  /// This style's raw fields without its role [token] — what a merged
  /// style lays over its materialised slot, and what an inline span draws.
  CoreTextStyle get _rawFields => CoreTextStyle(
    fontSize: fontSize,
    lineHeight: lineHeight,
    lineHeightPx: lineHeightPx,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    fontFamily: fontFamily,
    color: color,
  );
}

/// Flutter's `TextStyle.height` for [style] — a multiplier of the font
/// size it is drawn at.
///
/// A fixed line box ([CoreTextStyle.lineHeightPx]) wins over the
/// multiplier and becomes `px / fontSize`, so it needs the final size:
/// [fontSize] when the caller knows a size [style] does not state, else
/// the style's own. With no size to divide by the height is left to
/// inherit rather than falling back to the multiplier the box overrode.
double? _heightOf(CoreTextStyle style, {double? fontSize}) {
  final px = style.lineHeightPx;
  if (px == null) return style.lineHeight;
  final size = fontSize ?? style.fontSize;

  return size == null || size == 0 ? null : px / size;
}

/// `CoreCubicBezier` → Flutter `Curve`.
///
/// `coui_core` stores easing as 4 control points only; this conversion
/// lives in `coui_flutter` so the core package stays Flutter-free.
///
/// Usage — prefer the semantic alias tier (`CoreEasing.move` /
/// `decelerate` / `accelerate` / `spring`) over a raw curve name so a
/// future systemic easing override has one vocabulary to act on:
/// ```dart
/// AnimatedContainer(
///   duration: const Duration(milliseconds: 300),
///   curve: CoreEasing.enter.toValue(),
///   child: ...,
/// )
/// ```
extension CoreCubicBezierToFlutter on CoreCubicBezier {
  /// Converts to a Flutter [Cubic] curve.
  Curve toValue() => Cubic(x1, y1, x2, y2);
}

/// `CoreEasingFunction` → Flutter `Curve`.
extension CoreEasingFunctionToFlutter on CoreEasingFunction {
  /// Returns the corresponding Flutter [Curve].
  Curve toValue() => switch (this) {
    .decelerate => Curves.decelerate,
    .bounceIn => Curves.bounceIn,
    .bounceOut => Curves.bounceOut,
    .bounceInOut => Curves.bounceInOut,
    .elasticIn => Curves.elasticIn,
    .elasticOut => Curves.elasticOut,
    .elasticInOut => Curves.elasticInOut,
    .easeInOutCubicEmphasized => Curves.easeInOutCubicEmphasized,
    .fastEaseInToSlowEaseOut => Curves.fastEaseInToSlowEaseOut,
  };
}

/// Resolves a CoUI typography role (built via
/// `CoreTextStyle.token(CoreTextStyles.X)`) to the matching Flutter
/// [TextStyle] using the active theme's [ThemeData.typography].
///
/// Mirrors the colour axis (`scheme.resolve(color).toValue()`):
///
/// ```dart
/// theme.typography.resolve(textStyle).toValue()
/// ```
///
/// `typography.resolve` materialises the token slot (raw fields
/// populated); `.toValue()` then converts to a Flutter `TextStyle`.
TextStyle resolveTypographyRole(ThemeData theme, CoreTextStyle role) {
  return theme.typography.resolve(role).toValue();
}

/// Merges a [CoreTextStyle] [override] onto a base Flutter [TextStyle],
/// resolving the override's colour through the active [scheme] so dark
/// mode tracks (never freezes the light value). Returns [base] unchanged
/// when [override] is null; each non-null override field wins (mirrors
/// `TextStyle.merge`).
///
/// - colour: `scheme.resolve(color).toValue()` — light/dark aware.
/// - `letterSpacing`: stored on [CoreTextStyle] as an em ratio, so it is
///   multiplied by the effective font size to yield Flutter's logical-px
///   `letterSpacing`.
/// - line height: a fixed line box (`lineHeightPx`) wins over the
///   multiplier and is divided by the effective font size, as in
///   [CoreTextStyleToFlutter.toValue].
/// - family: naming a family brings that family's fallback stack, so a
///   mono override on a sans base falls back to the bundled Geist Mono
///   rather than keeping the sans fallback.
///
/// The [base] is a Flutter `TextStyle` and carries no line box of its own
/// — only a ratio — so an override that changes only `fontSize` on a base
/// drawn from a code role scales that role's line with it. State the box
/// on the override (or overlay the role before converting) to keep it.
///
/// Single CoreTextStyle→TextStyle merge site — shared by per-item label
/// composition and by resolver slot overlays alike.
TextStyle applyCoreTextStyle(
  TextStyle base,
  CoreTextStyle? override,
  CoreColorScheme scheme,
) {
  if (override == null) return base;
  final fontSize = override.fontSize ?? base.fontSize;
  final family = override.fontFamily;

  return base.copyWith(
    color: override.color == null
        ? base.color
        : scheme.resolve(override.color!).toValue(),
    fontSize: fontSize,
    fontWeight:
        fontWeightFromInt(
          override.fontWeight,
          orElse: base.fontWeight ?? .normal,
        ) ??
        base.fontWeight,
    letterSpacing: override.letterSpacing != null
        ? override.letterSpacing! * (fontSize ?? 0)
        : base.letterSpacing,
    height: override.lineHeightPx != null
        ? _heightOf(override, fontSize: fontSize)
        : override.lineHeight ?? base.height,
    fontFamily: family ?? base.fontFamily,
    fontFamilyFallback: family == null
        ? base.fontFamilyFallback
        : _fallbackFor(family),
  );
}

// ─── Font-family stacks (Flutter EMIT) ────────────────────────────────
//
// Primary families are the platform-neutral [CoreFontFamily] tokens
// (Pretendard / Geist Mono). The fallback families are the
// `coui_flutter`-bundled Geist fonts (package-qualified — a Flutter-only
// vocabulary that must not live in `coui_core`), so the package renders
// deterministically without an app-provided font (tests, bare apps). The
// bundled GeistMono is the mono token's own face, so mono text draws the
// same glyphs whether or not the app ships Geist Mono; GeistSans is a
// metric stand-in behind the app-provided Pretendard. The Web side states
// the same stacks through `--coui-font-family-*` in `theme_config`
// (`"Geist Mono", "Pretendard", monospace` for mono).

/// Bundled `GeistSans` fallback, package-qualified for `fontFamilyFallback`.
const String _kGeistSansFallback = 'packages/coui_flutter/GeistSans';

/// Bundled `GeistMono` fallback, package-qualified for `fontFamilyFallback`.
const String _kGeistMonoFallback = 'packages/coui_flutter/GeistMono';

/// Shared sans fallback list — the bundled Geist fallback behind the
/// primary [CoreFontFamily.sans], reused by [kCoreSansTextStyle] and the
/// `CoreTextStyle.toValue` family pin.
const List<String> kCoreSansFontFallback = [_kGeistSansFallback];

/// Shared mono fallback list — the bundled GeistMono, the same face as the
/// primary [CoreFontFamily.mono], so an app that ships no Geist Mono still
/// draws it; then the text face [CoreFontFamily.sans] for the Hangul Geist
/// Mono lacks. Carried by every style that names the mono face (the code
/// roles, a mono override) and by [kCoreMonoTextStyle] alike.
const List<String> kCoreMonoFontFallback = [
  _kGeistMonoFallback,
  CoreFontFamily.sans,
];

/// The fallback list for a family a style names — or none ([family] null).
///
/// - none, or the text face itself — the bundled Geist fallback. Naming the
///   text face is the same as naming nothing; without this, setting it on a
///   role dropped the fallback and the role drew in the platform default
///   wherever the app had not supplied the face.
/// - the mono face — [kCoreMonoFontFallback]: the bundled Geist Mono, then
///   the text face for Hangul.
/// - any other face (a product's display face, set with
///   `CoreTypography.withFamily`) — the text face, then Geist, so glyphs the
///   face lacks (Hangul, for most Latin display faces) draw in the text face
///   rather than the platform default. The Web stack says the same thing
///   through `--coui-text-{role}-family`.
List<String>? _fallbackFor(String? family) => switch (family) {
  null || CoreFontFamily.sans => kCoreSansFontFallback,
  CoreFontFamily.mono => kCoreMonoFontFallback,
  _ => const [CoreFontFamily.sans, _kGeistSansFallback],
};

/// Canonical sans-serif `TextStyle`: primary [CoreFontFamily.sans]
/// (Pretendard) → bundled `GeistSans` fallback.
const TextStyle kCoreSansTextStyle = TextStyle(
  fontFamily: CoreFontFamily.sans,
  fontFamilyFallback: kCoreSansFontFallback,
);

/// Canonical monospace `TextStyle`: primary [CoreFontFamily.mono]
/// (Geist Mono) → [kCoreMonoFontFallback] (the bundled `GeistMono`, then
/// [CoreFontFamily.sans] for the Hangul Geist Mono lacks).
const TextStyle kCoreMonoTextStyle = TextStyle(
  fontFamily: CoreFontFamily.mono,
  fontFamilyFallback: kCoreMonoFontFallback,
);

/// An extra condition Flutter puts on a role before it may be stated.
///
/// Several of Flutter's role checks are structural — a tab bar's
/// children, a menu item's ancestor — and can only be satisfied by the
/// component that owns the subtree. These are the ones a wrapper can
/// see, so they travel with the role rather than being re-derived at
/// each site.
enum SemanticRolePrecondition {
  /// Nothing beyond the role itself.
  none,

  /// The node needs an accessible name. An unnamed region is what the
  /// SDK check rejects, and it conveys nothing anyway.
  label,

  /// The node announces which of a set is current, and is operable.
  selectionAndTap,

  /// The node announces a checked state.
  ///
  /// A menu entry that toggles is the reason: without the state it is
  /// indistinguishable from a plain entry, and a reader that says
  /// "checkbox" with nothing after it has told the user less than if it
  /// had said nothing.
  checkedState,

  /// The node carries a value and both ends of its range.
  valueRange,
}

/// What a [CoreSemanticRole] becomes in Flutter's semantics tree.
///
/// Flutter's role vocabulary is narrower than ARIA's, so one Core role
/// fans out to a native role, a flag, or nothing at all — see
/// [CoreSemanticRoleSupport]. Grouping the outcome in one value keeps
/// the translation in a single switch instead of at each of the ~90
/// hand-written `Semantics(` sites.
@immutable
class FlutterSemanticRole {
  /// Creates a [FlutterSemanticRole]. Every field is optional because
  /// most roles set exactly one of them.
  const FlutterSemanticRole({
    this.role,
    this.button,
    this.link,
    this.image,
    this.slider,
    this.header,
    this.liveRegion,
    this.inMutuallyExclusiveGroup,
    this.container = false,
    this.excludeSemantics = false,
    this.precondition = .none,
  });

  /// The native role, when Flutter has one.
  final SemanticsRole? role;

  /// `Semantics.button`.
  final bool? button;

  /// `Semantics.link`.
  final bool? link;

  /// `Semantics.image`.
  final bool? image;

  /// `Semantics.slider`.
  final bool? slider;

  /// `Semantics.header`.
  final bool? header;

  /// `Semantics.liveRegion` — how `status` / `alert` are announced.
  final bool? liveRegion;

  /// `Semantics.inMutuallyExclusiveGroup`.
  final bool? inMutuallyExclusiveGroup;

  /// `Semantics.container`.
  final bool container;

  /// `Semantics.excludeSemantics` — how `presentation` is expressed.
  final bool excludeSemantics;

  /// What else must hold before [role] may be stated.
  final SemanticRolePrecondition precondition;
}

/// Translates a [CoreSemanticRole] into Flutter's semantics vocabulary.
///
/// The switch is exhaustive: adding a value to the enum breaks this
/// file until Flutter states an answer, which is the compile-time
/// equivalent of the "make the redefinition point required" rule in
/// `core/theme-axis-composition.md`. A grep guard is the second line,
/// not the first.
extension CoreSemanticRoleToFlutter on CoreSemanticRole {
  /// The Flutter expression of this role.
  ///
  /// Roles that are not [CoreSemanticRoleSupport.mapped] never produce
  /// a native [SemanticsRole] — five of Flutter's own role values have
  /// no debug check registered and raise `Missing checks for role`
  /// from an assert that runs in every widget test touching
  /// semantics, so the degradation is not cosmetic.
  FlutterSemanticRole toValue() {
    final resolved = switch (this) {
      // mapped — Flutter has the role.
      .tabList => const FlutterSemanticRole(
        role: .tabBar,
      ),
      .tab => const FlutterSemanticRole(
        role: .tab,
        precondition: .selectionAndTap,
      ),
      .tabPanel => const FlutterSemanticRole(
        role: .tabPanel,
      ),
      .dialog => const FlutterSemanticRole(
        role: .dialog,
      ),
      .menu => const FlutterSemanticRole(
        role: .menu,
      ),
      .menuBar => const FlutterSemanticRole(
        role: .menuBar,
      ),
      .menuItem => const FlutterSemanticRole(
        role: .menuItem,
      ),
      .menuItemCheckbox => const FlutterSemanticRole(
        role: .menuItemCheckbox,
        precondition: .checkedState,
      ),
      .menuItemRadio => const FlutterSemanticRole(
        role: .menuItemRadio,
        // One choice of a group: checking it unchecks the others.
        inMutuallyExclusiveGroup: true,
        precondition: .checkedState,
      ),
      .list => const FlutterSemanticRole(
        role: .list,
      ),
      // No precondition it can state from here: what a list item needs
      // is a list *above* it, which this sees nothing of. The SDK
      // asserts that relationship, so a misplaced item fails loudly at
      // the point it is built rather than reading a position it does
      // not have.
      .listItem => const FlutterSemanticRole(
        role: .listItem,
      ),
      .radioGroup => const FlutterSemanticRole(
        role: .radioGroup,
      ),
      .progressBar => const FlutterSemanticRole(
        role: .progressBar,
        precondition: .valueRange,
      ),
      // Flutter has no distinct grid role — a grid's interactivity is
      // conveyed by its cells (`gridCell`, `button:`, …), not the
      // container, so the same native `table` role answers both.
      .table || .grid => const FlutterSemanticRole(
        role: .table,
      ),
      .row => const FlutterSemanticRole(
        role: .row,
      ),
      // Same native role for both — see `CoreSemanticRole.gridCell`.
      .cell || .gridCell => const FlutterSemanticRole(
        role: .cell,
      ),
      .columnHeader => const FlutterSemanticRole(
        role: .columnHeader,
      ),
      // Landmarks all require a name, for the same reason a region
      // does: a page usually has more than one, and a list of landmarks
      // that reads "navigation, navigation, navigation" is a list the
      // user cannot choose from. The SDK rejects an unnamed region
      // outright; the others it accepts and then leaves ambiguous, which
      // is the worse failure because nothing says so.
      .main => const FlutterSemanticRole(
        role: .main,
        precondition: .label,
      ),
      .navigation => const FlutterSemanticRole(
        role: .navigation,
        precondition: .label,
      ),
      .region => const FlutterSemanticRole(
        role: .region,
        precondition: .label,
      ),
      .contentInfo => const FlutterSemanticRole(
        role: .contentInfo,
        precondition: .label,
      ),

      // flagged — the canonical Flutter mechanism is a flag. `checkbox`
      // and `toggleSwitch` carry theirs on the component's own
      // `checked:` / `toggled:` state, which the role cannot know.
      .button => const FlutterSemanticRole(button: true),
      .link => const FlutterSemanticRole(link: true),
      .image => const FlutterSemanticRole(image: true),
      // Same native flag for all three — see `CoreSemanticRole.separator`
      // and `CoreSemanticRole.scrollbar`.
      .slider ||
      .separator ||
      .scrollbar => const FlutterSemanticRole(slider: true),
      .banner => const FlutterSemanticRole(header: true),
      .group => const FlutterSemanticRole(container: true),
      .presentation => const FlutterSemanticRole(
        excludeSemantics: true,
      ),
      .radio => const FlutterSemanticRole(
        inMutuallyExclusiveGroup: true,
      ),
      // Nothing reaches the tree, for three different reasons — all
      // recorded on the enum, which is where the distinction matters.
      // `checkbox` / `toggleSwitch` / `textbox` are flagged, but by the
      // component's own `checked:` / `toggled:` / text-field state rather
      // than by the role. `application` / `listBox` / `option` / `tree` /
      // `treeItem` / `toolbar` have no Flutter expression at all. `tooltip` / `comboBox` have one
      // that raises `Missing checks for role` from an assert reached by
      // every widget test touching semantics.
      .checkbox ||
      .toggleSwitch ||
      .textbox ||
      .application ||
      .listBox ||
      .option ||
      .tree ||
      .treeItem ||
      .toolbar ||
      .tooltip ||
      .comboBox => const FlutterSemanticRole(),

      // `status` and `alert` are mutually exclusive with the live
      // region that actually gets announced, so the live region wins.
      .status || .alert => const FlutterSemanticRole(liveRegion: true),
    };

    assert(
      support == .mapped || resolved.role == null,
      'CoreSemanticRole.$name is declared ${support.name} but produced a '
      'native SemanticsRole. A role Flutter cannot safely express must '
      'not reach the semantics tree.',
    );

    return resolved;
  }
}

/// Core → Flutter: a morph silhouette as a clip path.
extension CoreLiquidMorphOutlineToFlutter on CoreLiquidMorphOutline {
  /// The outline as a closed [Path], ready for a `ClipPath`.
  ///
  /// Straight segments, deliberately. The outline is already sampled fine
  /// enough that its vertices sit under a device pixel at the sizes an
  /// overlay opens at, so fitting curves through them would spend time
  /// smoothing something that is already smooth — and would introduce a
  /// second interpretation of the same points, which the Web half does not
  /// share.
  ///
  /// Empty when the walk found no crossing. A caller with an empty outline
  /// should skip clipping rather than clip to nothing: an empty path clips
  /// everything away, so a shape that failed to trace would render as a
  /// missing panel rather than an unclipped one.
  Path toValue() {
    final path = Path();
    for (final contour in contours) {
      if (contour.isEmpty) continue;

      path.moveTo(contour.first.x, contour.first.y);
      for (final point in contour.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      path.close();
    }

    // Every loop goes in, as its own subpath. `Path` unions them under its
    // default non-zero fill, which is what the field says is there: for
    // part of the flight the silhouette genuinely is two bodies, and
    // drawing only the first one carved the panel down to whichever the
    // grid scan reached first.
    return path;
  }
}
