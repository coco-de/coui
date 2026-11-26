import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_size.dart';
import 'package:meta/meta.dart';

/// The document attribute a Web page — or a part of one — carries while its
/// typography tier is pinned rather than read off the viewport.
///
/// Lives here for the reason `kDensityAttribute` does: the stylesheet that
/// writes rules for it, the switch that sets it and any consumer that reads
/// it must agree on one string, and a second spelling anywhere is a silent
/// no-op rather than an error.
const String kTypographyTierAttribute = 'data-coui-typography-tier';

/// The six heading sizes of one viewport tier — display and headline, large
/// to small.
///
/// The tier moves these roles and no others. A heading is sized against the
/// width of the screen it heads, so it steps down with the screen; title,
/// body, label and code set running copy and controls, which read the same
/// at any width.
///
/// Every field is required, so a tier row is a compile-time list of all six
/// headings — a heading left out of a row would draw its desktop size on a
/// phone with nothing to say so.
@immutable
class CoreHeadingSizes {
  /// Creates the six heading sizes of one tier.
  const CoreHeadingSizes({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
  });

  /// Display large.
  final double displayLarge;

  /// Display medium.
  final double displayMedium;

  /// Display small.
  final double displaySmall;

  /// Headline large.
  final double headlineLarge;

  /// Headline medium.
  final double headlineMedium;

  /// Headline small.
  final double headlineSmall;

  /// CoUI's heading sizes below desktop: display steps 8px per tier and
  /// headline 4px.
  ///
  /// Desktop has no row. It is the scale as authored — `CoreTypography.coui`
  /// — the way `CoreDensity.standard` is the values as authored, and a row
  /// for it here would be a second statement of six sizes the scale already
  /// states. The Figma library's Mobile · Tablet modes are these numbers:
  /// the token export reads them from here.
  static const Map<CoreBreakpointTier, CoreHeadingSizes> couiByTier = {
    CoreBreakpointTier.mobile: CoreHeadingSizes(
      displayLarge: CoreFontSize.s36,
      displayMedium: CoreFontSize.s32,
      displaySmall: CoreFontSize.s28,
      headlineLarge: CoreFontSize.s24,
      headlineMedium: CoreFontSize.s20,
      headlineSmall: CoreFontSize.s16,
    ),
    CoreBreakpointTier.tablet: CoreHeadingSizes(
      displayLarge: CoreFontSize.s44,
      displayMedium: CoreFontSize.s40,
      displaySmall: CoreFontSize.s36,
      headlineLarge: CoreFontSize.s28,
      headlineMedium: CoreFontSize.s24,
      headlineSmall: CoreFontSize.s20,
    ),
  };

  /// The size this row gives [token] — one of the six heading roles.
  ///
  /// Throws an [ArgumentError] for any other role: a tier has no size for
  /// it, and a fallback here would make a role nobody stepped look stepped.
  double sizeOf(CoreTextStyleToken token) => switch (token) {
    CoreTextStyles.displayLarge => displayLarge,
    CoreTextStyles.displayMedium => displayMedium,
    CoreTextStyles.displaySmall => displaySmall,
    CoreTextStyles.headlineLarge => headlineLarge,
    CoreTextStyles.headlineMedium => headlineMedium,
    CoreTextStyles.headlineSmall => headlineSmall,
    _ => throw ArgumentError.value(
      token,
      'token',
      'not a heading role — a viewport tier sizes display and headline only',
    ),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHeadingSizes &&
          displayLarge == other.displayLarge &&
          displayMedium == other.displayMedium &&
          displaySmall == other.displaySmall &&
          headlineLarge == other.headlineLarge &&
          headlineMedium == other.headlineMedium &&
          headlineSmall == other.headlineSmall;

  @override
  int get hashCode => Object.hash(
    displayLarge,
    displayMedium,
    displaySmall,
    headlineLarge,
    headlineMedium,
    headlineSmall,
  );
}
