import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:meta/meta.dart';

/// A WCAG 2.x contrast success criterion, with the ratio it requires.
///
/// The criterion is picked by **what is drawn**, not by how important it
/// looks: body text is [aaNormalText], text at least 18pt (24px) or 14pt
/// (≈18.67px) bold is [aaLargeText], and a control boundary, focus
/// indicator or meaningful icon is [nonText]. Disabled controls and pure
/// decoration are exempt from all of them.
enum CoreContrastLevel {
  /// WCAG 1.4.3 Contrast (Minimum), normal-size text — 4.5:1.
  aaNormalText(4.5),

  /// WCAG 1.4.3 Contrast (Minimum), large text — 3:1.
  aaLargeText(3),

  /// WCAG 1.4.6 Contrast (Enhanced), normal-size text — 7:1.
  aaaNormalText(7),

  /// WCAG 1.4.6 Contrast (Enhanced), large text — 4.5:1.
  aaaLargeText(4.5),

  /// WCAG 1.4.11 Non-text Contrast (component boundaries, icons) — 3:1.
  nonText(3);

  const CoreContrastLevel(this.minimumRatio);

  /// The lowest contrast ratio that satisfies this criterion.
  final double minimumRatio;

  /// Whether [ratio] satisfies this criterion.
  ///
  /// Compared unrounded, as WCAG requires: 4.49:1 does not pass a 4.5:1
  /// criterion even though it displays as "4.5".
  bool isMetBy(double ratio) => ratio >= minimumRatio;
}

/// WCAG 2.x relative luminance, contrast ratio and pass/fail judgement for
/// [CoreColor] values.
///
/// Pure Dart, so the same numbers come out in a Flutter app, a Jaspr page,
/// a unit test and a build tool:
///
/// ```dart
/// final scheme = CoreSemanticMapping.light(palette).resolved(.light);
/// CoreContrast.ratio(scheme.onSurface, scheme.surface); // e.g. 17.4
/// CoreContrast.meets(scheme.onPrimary, scheme.primary, .aaNormalText);
/// expect(CoreContrast.auditScheme(scheme).failures, isEmpty);
/// ```
///
/// **Alpha.** Contrast is only defined between two opaque colours, because
/// a translucent colour has no luminance of its own — what the eye sees is
/// whatever shows through it. So:
///
/// - [relativeLuminance] rejects a translucent colour with an
///   [ArgumentError]; composite it first ([compositeOver]).
/// - [ratio] and [meets] composite a translucent **foreground** over the
///   background (source-over, the way a label or wash is painted) and
///   measure the result.
/// - A translucent **background** is rejected with an [ArgumentError]: its
///   contrast depends on what sits behind it, which no pair of colours can
///   settle. Pass the opaque colour it ends up as on screen.
///
/// **Tokens.** An unresolved `CoreColor.token(...)` has no channels yet and
/// throws a [StateError]. Read colours from a resolved scheme
/// (`ResolvedColorScheme`, or `scheme.resolve(token)` in Flutter).
abstract final class CoreContrast {
  /// Contrast of black against white — the largest ratio WCAG can produce.
  static const double maxRatio = 21;

  /// Contrast of any colour against itself — the smallest ratio.
  static const double minRatio = 1;

  // WCAG 2.x relative-luminance weights (ITU-R BT.709 primaries) and the
  // flare term added to both sides of the ratio. Spec values, not tuning
  // knobs: nudging one silently changes every ratio in the kit.
  static const double _kRedWeight = 0.2126;
  static const double _kGreenWeight = 0.7152;
  static const double _kBlueWeight = 0.0722;
  static const double _kFlare = 0.05;

  /// WCAG 2.x relative luminance of an opaque [color], from 0 (black) to 1
  /// (white).
  ///
  /// Each channel is decoded from sRGB to linear light with
  /// [CoreColorConversion.srgbToLinear] — the same transfer function the
  /// OKLab conversion uses — then weighted 0.2126 R + 0.7152 G + 0.0722 B.
  ///
  /// Throws an [ArgumentError] when [color] is translucent and a
  /// [StateError] when it is an unresolved token (see the class docs).
  static double relativeLuminance(CoreColor color) {
    _requireOpaque(color, 'color');

    return _kRedWeight * _linear(color.red) +
        _kGreenWeight * _linear(color.green) +
        _kBlueWeight * _linear(color.blue);
  }

  /// WCAG 2.x contrast ratio of [foreground] drawn on [background], from
  /// [minRatio] (1) to [maxRatio] (21).
  ///
  /// Symmetric for opaque colours. A translucent [foreground] is measured
  /// as composited over [background]; a translucent [background] throws an
  /// [ArgumentError] (see the class docs).
  static double ratio(CoreColor foreground, CoreColor background) {
    _requireOpaque(background, 'background');
    final first = relativeLuminance(compositeOver(foreground, background));
    final second = relativeLuminance(background);
    final lighter = first > second ? first : second;
    final darker = first > second ? second : first;

    return (lighter + _kFlare) / (darker + _kFlare);
  }

  /// Whether [foreground] on [background] satisfies [level].
  static bool meets(
    CoreColor foreground,
    CoreColor background,
    CoreContrastLevel level,
  ) => level.isMetBy(ratio(foreground, background));

  /// [foreground] painted over an opaque [background] with source-over
  /// blending, rounded to 8-bit channels — the colour a screen shows.
  ///
  /// Returns [foreground] unchanged when it is already opaque.
  static CoreColor compositeOver(CoreColor foreground, CoreColor background) {
    _requireOpaque(background, 'background');
    final alpha = foreground.alpha;
    if (alpha == CoreColorConversion.alphaMax) return foreground;
    final t = alpha / CoreColorConversion.alphaMax;

    int blend(int top, int bottom) =>
        (top * t + bottom * (1 - t)).round().clamp(
          CoreColorConversion.channelMin,
          CoreColorConversion.rgbMax,
        );

    return CoreColor.fromARGB(
      CoreColorConversion.alphaMax,
      blend(foreground.red, background.red),
      blend(foreground.green, background.green),
      blend(foreground.blue, background.blue),
    );
  }

  /// Checks the representative foreground/background pairs of a resolved
  /// [scheme] and returns a report — one line in an app test or a golden
  /// test:
  ///
  /// ```dart
  /// final report = CoreContrast.auditScheme(
  ///   CoreSemanticMapping.light(palette).resolved(.light),
  /// );
  /// expect(report.failures, isEmpty, reason: report.toString());
  /// ```
  ///
  /// The pairs are the couplings the scheme exists to render: `onX` drawn
  /// on `X` for every role and its container, the surface foregrounds and
  /// `placeholder` and the third text tier `onSurfaceSubtle` on the page, the
  /// text-role primaries at the bound each
  /// one is named for (`primaryText` 4.5:1, `primaryTextLarge` 3:1),
  /// `error` as text on the page, the inverse surface, and `outline` and the
  /// four status indicators (`errorIcon` …) as non-text marks (3:1). Text
  /// pairs are held to [CoreContrastLevel.aaNormalText].
  ///
  /// It is a representative check, not an exhaustive one: a foreground on
  /// every surface container tone, hover/pressed fills and component
  /// variants are left to the app's own pairs ([ratio] / [meets]).
  /// `outlineVariant` and `outlineSubtle` (decorative hairlines) and
  /// disabled tones are not checked, because WCAG does not hold them to a
  /// ratio. Nor are the category colours: their bars change by mode — the
  /// light strong chip label is allowed 3.5:1, which no [CoreContrastLevel]
  /// states — so CoUI's own contrast gate audits their pairs mode by mode,
  /// and an app checks the ones it draws with [ratio].
  static CoreContrastReport auditScheme(ResolvedColorScheme scheme) {
    CoreContrastCheck text(
      String foregroundName,
      CoreColor foreground,
      String backgroundName,
      CoreColor background,
    ) => CoreContrastCheck(
      foregroundName: foregroundName,
      foreground: foreground,
      backgroundName: backgroundName,
      background: background,
      level: .aaNormalText,
    );

    final s = scheme;

    return CoreContrastReport([
      text('onSurface', s.onSurface, 'surface', s.surface),
      text('onSurfaceVariant', s.onSurfaceVariant, 'surface', s.surface),
      text('onSurface', s.onSurface, 'surfaceContainer', s.surfaceContainer),
      text(
        'onSurfaceVariant',
        s.onSurfaceVariant,
        'surfaceContainer',
        s.surfaceContainer,
      ),
      text('onSurfaceSubtle', s.onSurfaceSubtle, 'surface', s.surface),
      text('placeholder', s.placeholder, 'surface', s.surface),
      text('primaryText', s.primaryText, 'surface', s.surface),
      CoreContrastCheck(
        foregroundName: 'primaryTextLarge',
        foreground: s.primaryTextLarge,
        backgroundName: 'surface',
        background: s.surface,
        level: .aaLargeText,
      ),
      // `error` is painted as text on the page — a field's error message,
      // a destructive ghost button's label — not only as a fill.
      text('error', s.error, 'surface', s.surface),
      text('onPrimary', s.onPrimary, 'primary', s.primary),
      text(
        'onPrimaryContainer',
        s.onPrimaryContainer,
        'primaryContainer',
        s.primaryContainer,
      ),
      text('onSecondary', s.onSecondary, 'secondary', s.secondary),
      text(
        'onSecondaryContainer',
        s.onSecondaryContainer,
        'secondaryContainer',
        s.secondaryContainer,
      ),
      text('onTertiary', s.onTertiary, 'tertiary', s.tertiary),
      text(
        'onTertiaryContainer',
        s.onTertiaryContainer,
        'tertiaryContainer',
        s.tertiaryContainer,
      ),
      text('onError', s.onError, 'error', s.error),
      text(
        'onErrorContainer',
        s.onErrorContainer,
        'errorContainer',
        s.errorContainer,
      ),
      text('onSuccess', s.onSuccess, 'success', s.success),
      text(
        'onSuccessContainer',
        s.onSuccessContainer,
        'successContainer',
        s.successContainer,
      ),
      text('onWarning', s.onWarning, 'warning', s.warning),
      text(
        'onWarningContainer',
        s.onWarningContainer,
        'warningContainer',
        s.warningContainer,
      ),
      text('onInfo', s.onInfo, 'info', s.info),
      text(
        'onInfoContainer',
        s.onInfoContainer,
        'infoContainer',
        s.infoContainer,
      ),
      text(
        'inverseOnSurface',
        s.inverseOnSurface,
        'inverseSurface',
        s.inverseSurface,
      ),
      CoreContrastCheck(
        foregroundName: 'outline',
        foreground: s.outline,
        backgroundName: 'surface',
        background: s.surface,
        level: .nonText,
      ),
      CoreContrastCheck(
        foregroundName: 'errorIcon',
        foreground: s.errorIcon,
        backgroundName: 'surface',
        background: s.surface,
        level: .nonText,
      ),
      CoreContrastCheck(
        foregroundName: 'successIcon',
        foreground: s.successIcon,
        backgroundName: 'surface',
        background: s.surface,
        level: .nonText,
      ),
      CoreContrastCheck(
        foregroundName: 'warningIcon',
        foreground: s.warningIcon,
        backgroundName: 'surface',
        background: s.surface,
        level: .nonText,
      ),
      CoreContrastCheck(
        foregroundName: 'infoIcon',
        foreground: s.infoIcon,
        backgroundName: 'surface',
        background: s.surface,
        level: .nonText,
      ),
    ]);
  }

  static double _linear(int channel) =>
      CoreColorConversion.srgbToLinear(channel / CoreColorConversion.rgbScale);

  static void _requireOpaque(CoreColor color, String name) {
    if (color.alpha != CoreColorConversion.alphaMax) {
      throw ArgumentError.value(
        color,
        name,
        'must be opaque — a translucent colour has no contrast of its own '
        'until it is composited over what sits behind it',
      );
    }
  }
}

/// One foreground/background pair judged against a [CoreContrastLevel].
@immutable
class CoreContrastCheck {
  /// Creates a check of [foreground] drawn on [background] at [level].
  ///
  /// The names label the pair in [toString] and in a
  /// [CoreContrastReport]; use the scheme slot names (`onSurface`) or any
  /// label that lets a reader find the pair.
  const CoreContrastCheck({
    required this.foregroundName,
    required this.foreground,
    required this.backgroundName,
    required this.background,
    required this.level,
  });

  /// Label of the foreground colour.
  final String foregroundName;

  /// The colour drawn on top (text, icon, boundary).
  final CoreColor foreground;

  /// Label of the background colour.
  final String backgroundName;

  /// The colour drawn underneath. Must be opaque.
  final CoreColor background;

  /// The criterion this pair is held to.
  final CoreContrastLevel level;

  /// The measured contrast ratio ([CoreContrast.ratio]).
  double get ratio => CoreContrast.ratio(foreground, background);

  /// Whether [ratio] satisfies [level].
  bool get passes => level.isMetBy(ratio);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreContrastCheck &&
          other.foregroundName == foregroundName &&
          other.foreground == foreground &&
          other.backgroundName == backgroundName &&
          other.background == background &&
          other.level == level);

  @override
  int get hashCode => Object.hash(
    foregroundName,
    foreground,
    backgroundName,
    background,
    level,
  );

  /// `onSurface on surface 17.40:1 ✓ aaNormalText (≥4.5)` — the ratio is
  /// shown to two decimals; the judgement uses the unrounded value.
  @override
  String toString() =>
      '$foregroundName on $backgroundName '
      '${ratio.toStringAsFixed(2)}:1 ${passes ? '✓' : '✗'} '
      '${level.name} (≥${level.minimumRatio})';
}

/// The result of checking several [CoreContrastCheck]s at once — what
/// [CoreContrast.auditScheme] returns.
@immutable
class CoreContrastReport {
  /// Creates a report over [checks], kept in the given order.
  CoreContrastReport(Iterable<CoreContrastCheck> checks)
    : checks = List.unmodifiable(checks);

  /// Every check, passing or not.
  final List<CoreContrastCheck> checks;

  /// The checks that fall below their level.
  List<CoreContrastCheck> get failures => [
    for (final check in checks)
      if (!check.passes) check,
  ];

  /// Whether every check passes.
  bool get passes => checks.every((check) => check.passes);

  /// One line per check — failures first — so a failing `expect` prints
  /// the pairs that need attention at the top.
  @override
  String toString() {
    final failing = failures;
    final passing = [
      for (final check in checks)
        if (check.passes) check,
    ];

    return [
      'CoreContrastReport: ${failing.length} of ${checks.length} pairs fail',
      for (final check in failing) '  $check',
      for (final check in passing) '  $check',
    ].join('\n');
  }
}
