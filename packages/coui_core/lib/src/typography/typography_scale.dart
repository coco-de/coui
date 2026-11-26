import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_family.dart';
import 'package:coui_core/src/typography/font_size.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/letter_spacing.dart';
import 'package:coui_core/src/typography/line_height.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/tracking_rule.dart';
import 'package:coui_core/src/typography/typography_tier.dart';
import 'package:meta/meta.dart';

/// 22-style typography scale (baseline only).
///
/// Display, headline and title each come in large / medium / small. Body
/// adds xs below small. Label runs xl2 · xl · large · medium · small · xs,
/// one pixel apart (16 … 11), because a control label spans a wider size
/// range than prose does — and it carries [CoreFontWeight.medium] where
/// body carries regular, so the two are told apart by weight rather than by
/// size alone. Code runs xs · sm · md (11 · 12 · 13) in
/// [CoreFontFamily.mono] on one fixed 21px line box ([CoreLineBox.px21]),
/// so a gutter of line numbers and the code beside it share a grid.
///
/// Every field is required. Constructing this type is therefore a
/// compile-time list of the whole scale, and a role added here breaks
/// every call site that builds one by hand — which is the point: a scale
/// with a silently-defaulted role is a scale nobody chose.
///
/// Both of those changes — 15 fields becoming 17, and label moving from
/// regular to medium — shipped in **0.131**, and that release announced
/// neither: the commit went out as a feature. So a consumer who upgraded
/// to 0.131 met the compile break and the weight shift with nothing in
/// the release notes to explain either. It is written here because
/// CHANGELOG is append-only and 0.131 can no longer say it. The move from
/// 17 to 22 fields is a breaking change for the same reason and is
/// announced as one; [couiV1] keeps the previous table for an app that
/// wants its old sizes back while it migrates.
@immutable
class CoreTypography {
  /// Creates a typography scale with all 22 styles specified explicitly.
  const CoreTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.bodyXs,
    required this.labelXl2,
    required this.labelXl,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.labelXs,
    required this.codeXs,
    required this.codeSm,
    required this.codeMd,
  });

  // === Baseline Styles (22) ===

  /// Display large.
  final CoreTextStyle displayLarge;

  /// Display medium.
  final CoreTextStyle displayMedium;

  /// Display small.
  final CoreTextStyle displaySmall;

  /// Headline large.
  final CoreTextStyle headlineLarge;

  /// Headline medium.
  final CoreTextStyle headlineMedium;

  /// Headline small.
  final CoreTextStyle headlineSmall;

  /// Title large.
  final CoreTextStyle titleLarge;

  /// Title medium.
  final CoreTextStyle titleMedium;

  /// Title small.
  final CoreTextStyle titleSmall;

  /// Body large.
  final CoreTextStyle bodyLarge;

  /// Body medium.
  final CoreTextStyle bodyMedium;

  /// Body small.
  final CoreTextStyle bodySmall;

  /// Body xs — 12px. Helper and error text under a field, card metadata.
  final CoreTextStyle bodyXs;

  /// Label xl2 — 16px, the largest label.
  ///
  /// Above [labelLarge] because the label family stopped at 14 and control
  /// size ladders do not: `Button` runs xs…xl2, so its two largest rungs fell
  /// out of the family into `bodyLarge` and lost the weight with it. The
  /// biggest buttons rendered LIGHTER than the medium ones.
  ///
  /// Named for the component size that needed it (`CoreComponentSize.xl2`)
  /// rather than continued as "extra-large", because that is what these two
  /// rungs are for — the family grew to meet a ladder, and the name says which.
  final CoreTextStyle labelXl2;

  /// Label xl — 15px. See [labelXl2].
  final CoreTextStyle labelXl;

  /// Label large.
  final CoreTextStyle labelLarge;

  /// Label medium.
  final CoreTextStyle labelMedium;

  /// Label small.
  final CoreTextStyle labelSmall;

  /// Label xs — 11px, the smallest label: key caps, count badges.
  final CoreTextStyle labelXs;

  /// Code xs — 11px mono on the 21px code line.
  final CoreTextStyle codeXs;

  /// Code sm — 12px mono on the 21px code line: line numbers, logs, paths.
  final CoreTextStyle codeSm;

  /// Code md — 13px mono on the 21px code line: editor body.
  final CoreTextStyle codeMd;

  /// CoUI designer-spec typography scale.
  static const coui = CoreTypography(
    // ─── Weight and tracking ─────────────────────────────────────────────
    //
    // Weight is one per role group: display · headline 700, title 600, body
    // 400, label 500, code 400. A heavier label (600 · 700) is a
    // component's statement — the same 14px label is 500 in a navigation
    // item and 600 in a button — so it lives in that component's style,
    // not in a role of its own.
    //
    // Tracking is two steps (`CoreLetterSpacing`): 20px and above −2%,
    // below −1%, mono 0.
    //
    // Display — bold / h140 / −2%
    displayLarge: CoreTextStyle(
      fontSize: CoreFontSize.s52,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    displayMedium: CoreTextStyle(
      fontSize: CoreFontSize.s48,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    displaySmall: CoreTextStyle(
      fontSize: CoreFontSize.s44,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    // Headline — bold / h140 / −2%
    headlineLarge: CoreTextStyle(
      fontSize: CoreFontSize.s32,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    headlineMedium: CoreTextStyle(
      fontSize: CoreFontSize.s28,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    headlineSmall: CoreTextStyle(
      fontSize: CoreFontSize.s24,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    // Title — semibold / h140 / −2% at 20, −1% below
    titleLarge: CoreTextStyle(
      fontSize: CoreFontSize.s20,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.semiBold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    titleMedium: CoreTextStyle(
      fontSize: CoreFontSize.s18,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.semiBold,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    titleSmall: CoreTextStyle(
      fontSize: CoreFontSize.s16,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.semiBold,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    // Body — regular / h150 / −1%
    //
    // Body is the one family set for reading more than one line — chat,
    // descriptions, a dialog's body — so it keeps a reading leading above
    // the 140% the single-line roles share.
    bodyLarge: CoreTextStyle(
      fontSize: CoreFontSize.s15,
      lineHeight: CoreLineHeight.h150,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    bodyMedium: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h150,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    bodySmall: CoreTextStyle(
      fontSize: CoreFontSize.s13,
      lineHeight: CoreLineHeight.h150,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    bodyXs: CoreTextStyle(
      fontSize: CoreFontSize.s12,
      lineHeight: CoreLineHeight.h150,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    // Label — medium / h140 / −1%
    //
    // ─── Why label is heavier than body ──────────────────────────────────────
    //
    // `body` is read, `label` NAMES something you act on, so the two are told
    // apart by weight and not by size alone: at 10–14px a regular weight reads
    // as caption rather than as an affordance. Label is `medium` where body is
    // `regular`.
    //
    // ─── Where the weight lives ──────────────────────────────────────────────
    //
    // The role owns the weight, and a label reads the role's `medium` unless
    // its component states another one on top. Button's variant rows and
    // Chip's size rows state none, so their labels draw the role's `medium`;
    // where a component does state one (a Badge count, a dark Tag), it does so
    // in the one place its label is built. A weight is stated on the label's
    // own style, never on an ambient wrapper around it — the label `Text`
    // carries an explicit weight from the resolver and an explicit style
    // beats an ambient one (measured: explicit w400 under an ambient w500
    // renders w400), so the wrapper's weight would change nothing it appears
    // to be about and reach only a raw widget handed to `prefix`/`suffix`, on
    // Flutter only, since Web has no such wrapper. Raising the role moves
    // every label that names it, at once, in the one place the value can be
    // read back from.
    //
    // ─── Why the label line is 140% ──────────────────────────────────────────
    //
    // A label inside a control whose height is a fixed rung (button, field,
    // select, tab) is centred in that rung, so the line box only has to fit:
    // at 140% the largest label of each rung still does (a 13px label boxes
    // to 18.2 inside a 32px button). The rest of the labels are not inside a
    // fixed rung — a badge, a key cap, a tooltip, a table cell grow from the
    // text — and those were drawn at 140% in the design they come from; a
    // tighter line made every one of them a few pixels short of it. And a
    // label that wraps (a long menu item, an alert title) needs a line it can
    // be read across.
    labelXl2: CoreTextStyle(
      fontSize: CoreFontSize.s16,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelXl: CoreTextStyle(
      fontSize: CoreFontSize.s15,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelLarge: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelMedium: CoreTextStyle(
      fontSize: CoreFontSize.s13,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelSmall: CoreTextStyle(
      fontSize: CoreFontSize.s12,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelXs: CoreTextStyle(
      fontSize: CoreFontSize.s11,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    // Code — mono / regular / 21px line box / no tracking
    //
    // The line box is fixed rather than a multiplier because the three sizes
    // share one grid: an editor's 12px line numbers sit beside its 13px code
    // on the same lines. No single multiplier lands 11 · 12 · 13 on one
    // height, and a near one drifts a few pixels over a screen of lines.
    // Tracking is zero because the advance IS the grid.
    codeXs: CoreTextStyle(
      fontSize: CoreFontSize.s11,
      lineHeightPx: CoreLineBox.px21,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.normal,
      fontFamily: CoreFontFamily.mono,
    ),
    codeSm: CoreTextStyle(
      fontSize: CoreFontSize.s12,
      lineHeightPx: CoreLineBox.px21,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.normal,
      fontFamily: CoreFontFamily.mono,
    ),
    codeMd: CoreTextStyle(
      fontSize: CoreFontSize.s13,
      lineHeightPx: CoreLineBox.px21,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.normal,
      fontFamily: CoreFontFamily.mono,
    ),
  );

  /// The CoUI scale before the v2 redesign — kept so an app can put its old
  /// text sizes back while it moves to [coui]: `CoreThemeData(typography:
  /// CoreTypography.couiV1)`.
  ///
  /// Body ran 18 · 16 · 14 and label 18 · 16 · 14 · 12 · 10 on a 120%
  /// label line, with headline at 600 and a five-step tracking curve.
  /// That table had no `bodyXs`, `labelXs` or code roles; here each takes
  /// the old role a component read in its place — `bodyXs` the old
  /// `bodySmall`, `labelXs` the old `labelSmall`, and the code roles the
  /// old `bodySmall` set in mono on its 160% line.
  ///
  /// It reverts the table, not the components: a component that now reads
  /// a different role (a small button reads `labelMedium` where it read
  /// `labelLarge`) reads the old value of that role.
  @Deprecated(
    'Use CoreTypography.coui (since 0.162) — couiV1 is the pre-v2 table, '
    'kept for two minors so an app can migrate its text sizes on its own '
    'schedule.',
  )
  static const couiV1 = CoreTypography(
    displayLarge: CoreTextStyle(
      fontSize: CoreFontSize.s52,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight,
    ),
    displayMedium: CoreTextStyle(
      fontSize: CoreFontSize.s48,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight,
    ),
    displaySmall: CoreTextStyle(
      fontSize: CoreFontSize.s44,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight,
    ),
    headlineLarge: CoreTextStyle(
      fontSize: CoreFontSize.s32,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.semiBold,
      letterSpacing: CoreLetterSpacing.tight,
    ),
    headlineMedium: CoreTextStyle(
      fontSize: CoreFontSize.s28,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.semiBold,
      letterSpacing: CoreLetterSpacing.tight,
    ),
    headlineSmall: CoreTextStyle(
      fontSize: CoreFontSize.s24,
      lineHeight: CoreLineHeight.h140,
      fontWeight: CoreFontWeight.semiBold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    titleLarge: CoreTextStyle(
      fontSize: CoreFontSize.s20,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight20,
    ),
    titleMedium: CoreTextStyle(
      fontSize: CoreFontSize.s18,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight15,
    ),
    titleSmall: CoreTextStyle(
      fontSize: CoreFontSize.s16,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.bold,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    bodyLarge: CoreTextStyle(
      fontSize: CoreFontSize.s18,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight15,
    ),
    bodyMedium: CoreTextStyle(
      fontSize: CoreFontSize.s16,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    bodySmall: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    bodyXs: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelXl2: CoreTextStyle(
      fontSize: CoreFontSize.s18,
      lineHeight: CoreLineHeight.h120,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight15,
    ),
    labelXl: CoreTextStyle(
      fontSize: CoreFontSize.s16,
      lineHeight: CoreLineHeight.h120,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelLarge: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h120,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight10,
    ),
    labelMedium: CoreTextStyle(
      fontSize: CoreFontSize.s12,
      lineHeight: CoreLineHeight.h120,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight5,
    ),
    labelSmall: CoreTextStyle(
      fontSize: CoreFontSize.s10,
      lineHeight: CoreLineHeight.h120,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight5,
    ),
    labelXs: CoreTextStyle(
      fontSize: CoreFontSize.s10,
      lineHeight: CoreLineHeight.h120,
      fontWeight: CoreFontWeight.medium,
      letterSpacing: CoreLetterSpacing.tight5,
    ),
    codeXs: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.normal,
      fontFamily: CoreFontFamily.mono,
    ),
    codeSm: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.normal,
      fontFamily: CoreFontFamily.mono,
    ),
    codeMd: CoreTextStyle(
      fontSize: CoreFontSize.s14,
      lineHeight: CoreLineHeight.h160,
      fontWeight: CoreFontWeight.regular,
      letterSpacing: CoreLetterSpacing.normal,
      fontFamily: CoreFontFamily.mono,
    ),
  );

  /// Applies [transform] to every role.
  ///
  /// The roles are listed here and nowhere else, so a caller that needs to
  /// bend one property across the whole scale — a surface style raising
  /// weight, say — cannot end up covering all but one of them.
  CoreTypography map(CoreTextStyle Function(CoreTextStyle style) transform) {
    return CoreTypography(
      displayLarge: transform(displayLarge),
      displayMedium: transform(displayMedium),
      displaySmall: transform(displaySmall),
      headlineLarge: transform(headlineLarge),
      headlineMedium: transform(headlineMedium),
      headlineSmall: transform(headlineSmall),
      titleLarge: transform(titleLarge),
      titleMedium: transform(titleMedium),
      titleSmall: transform(titleSmall),
      bodyLarge: transform(bodyLarge),
      bodyMedium: transform(bodyMedium),
      bodySmall: transform(bodySmall),
      bodyXs: transform(bodyXs),
      labelXl2: transform(labelXl2),
      labelXl: transform(labelXl),
      labelLarge: transform(labelLarge),
      labelMedium: transform(labelMedium),
      labelSmall: transform(labelSmall),
      labelXs: transform(labelXs),
      codeXs: transform(codeXs),
      codeSm: transform(codeSm),
      codeMd: transform(codeMd),
    );
  }

  /// Creates a scaled copy of the entire typography scale.
  CoreTypography scale(double factor) {
    return CoreTypography(
      displayLarge: displayLarge.scale(factor),
      displayMedium: displayMedium.scale(factor),
      displaySmall: displaySmall.scale(factor),
      headlineLarge: headlineLarge.scale(factor),
      headlineMedium: headlineMedium.scale(factor),
      headlineSmall: headlineSmall.scale(factor),
      titleLarge: titleLarge.scale(factor),
      titleMedium: titleMedium.scale(factor),
      titleSmall: titleSmall.scale(factor),
      bodyLarge: bodyLarge.scale(factor),
      bodyMedium: bodyMedium.scale(factor),
      bodySmall: bodySmall.scale(factor),
      bodyXs: bodyXs.scale(factor),
      labelXl2: labelXl2.scale(factor),
      labelXl: labelXl.scale(factor),
      labelLarge: labelLarge.scale(factor),
      labelMedium: labelMedium.scale(factor),
      labelSmall: labelSmall.scale(factor),
      labelXs: labelXs.scale(factor),
      codeXs: codeXs.scale(factor),
      codeSm: codeSm.scale(factor),
      codeMd: codeMd.scale(factor),
    );
  }

  /// Returns a copy of this scale with the given roles replaced.
  ///
  /// Lets a project override the composition of individual roles
  /// (e.g. `CoreTypography.coui.copyWith(bodyMedium: CoreTextStyle(...))`)
  /// without respecifying all of them — the single override surface that
  /// flows into `CoreThemeData.typography` for both Flutter and Web.
  CoreTypography copyWith({
    CoreTextStyle? displayLarge,
    CoreTextStyle? displayMedium,
    CoreTextStyle? displaySmall,
    CoreTextStyle? headlineLarge,
    CoreTextStyle? headlineMedium,
    CoreTextStyle? headlineSmall,
    CoreTextStyle? titleLarge,
    CoreTextStyle? titleMedium,
    CoreTextStyle? titleSmall,
    CoreTextStyle? bodyLarge,
    CoreTextStyle? bodyMedium,
    CoreTextStyle? bodySmall,
    CoreTextStyle? bodyXs,
    CoreTextStyle? labelXl2,
    CoreTextStyle? labelXl,
    CoreTextStyle? labelLarge,
    CoreTextStyle? labelMedium,
    CoreTextStyle? labelSmall,
    CoreTextStyle? labelXs,
    CoreTextStyle? codeXs,
    CoreTextStyle? codeSm,
    CoreTextStyle? codeMd,
  }) {
    return CoreTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      bodyXs: bodyXs ?? this.bodyXs,
      labelXl2: labelXl2 ?? this.labelXl2,
      labelXl: labelXl ?? this.labelXl,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      labelXs: labelXs ?? this.labelXs,
      codeXs: codeXs ?? this.codeXs,
      codeSm: codeSm ?? this.codeSm,
      codeMd: codeMd ?? this.codeMd,
    );
  }

  /// The heading roles — display and headline: the roles a display face goes
  /// to ([withFamily]) and the roles a viewport tier steps ([atTier]).
  ///
  /// Title, body and label stay in the text face: they set running copy
  /// and control labels, where a display face costs legibility and a
  /// change of face reads as a change of kind. For the same reason they
  /// keep one size at every viewport width.
  static const List<CoreTextStyleToken> headingRoles = [
    CoreTextStyles.displayLarge,
    CoreTextStyles.displayMedium,
    CoreTextStyles.displaySmall,
    CoreTextStyles.headlineLarge,
    CoreTextStyles.headlineMedium,
    CoreTextStyles.headlineSmall,
  ];

  /// Returns a copy of this scale that sets [roles] in [family].
  ///
  /// The default scale names a family on the code roles only (mono), so
  /// every other role draws in the text face (`CoreFontFamily.sans`). This
  /// is how a product gives its headings a face of their own without
  /// restating the roles — size, weight, leading and tracking stay the
  /// role's.
  ///
  /// [family] is a font name the app provides, as `CoreFontFamily.sans` is.
  /// Both platforms fall back to the text face for glyphs it lacks — Hangul,
  /// for most Latin display faces.
  CoreTypography withFamily(
    String family, {
    Iterable<CoreTextStyleToken> roles = headingRoles,
  }) => _mapRoles(roles, (_, style) => style.copyWith(fontFamily: family));

  /// Returns this scale as drawn at a viewport [tier] — the headings stepped
  /// to the tier's sizes, every other role as it is.
  ///
  /// The scale is taken to be drawn at [from], which is desktop — the scale
  /// as authored — unless said otherwise. [CoreBreakpointTier.desktop] from
  /// desktop returns this same instance, so the tier a desktop viewport
  /// resolves to costs nothing and changes nothing; so does any [tier] equal
  /// to [from].
  ///
  /// Each heading role is multiplied by the ratio CoUI's own scale steps
  /// that role by between the two tiers ([CoreHeadingSizes.couiByTier], with
  /// [CoreTypography.coui] as the desktop row) rather than set to the
  /// tier's size outright. A size stated outright would erase whatever
  /// already multiplied this scale — the text scaling a theme folds into its
  /// typography before the tier — and a product's own heading sizes; the
  /// ratio keeps both, and on CoUI's own scale it lands exactly on the
  /// table. A fixed line box moves by the same ratio, since it boxes the
  /// glyphs it holds. A scale already drawn at a tier steps from there, so
  /// a part of a page held to another tier (a subtree that keeps its
  /// desktop headings on a phone) steps up as well as down.
  ///
  /// Tracking is read again at the tier's size from
  /// [CoreTrackingRule.coui] — a 24px headline on −2% is a 16px one on −1%
  /// — where the role tracks the way that rule says its size at [from]
  /// does. A role that states tracking of its own (an app's, or [couiV1]'s
  /// curve) keeps it, and so does a monospace role, whose advance is its
  /// grid. Weight, leading and family stay the role's.
  CoreTypography atTier(
    CoreBreakpointTier tier, {
    CoreBreakpointTier from = CoreBreakpointTier.desktop,
  }) {
    if (tier == from) return this;
    final tracking = CoreTrackingRule.coui;
    // CoUI's size for [token] at [at] — the table's row, or the scale as
    // authored for desktop, which has none.
    double couiSizeAt(CoreBreakpointTier at, CoreTextStyleToken token) =>
        CoreHeadingSizes.couiByTier[at]?.sizeOf(token) ??
        token.read(coui).fontSize!;

    return _mapRoles(headingRoles, (token, style) {
      final size = style.fontSize;
      // A role that states no size inherits one; there is nothing here to
      // step.
      if (size == null) return style;
      final drawn = couiSizeAt(from, token);
      final stepped = couiSizeAt(tier, token);
      final box = style.lineHeightPx;
      final spacing = style.letterSpacing;
      final followsRule =
          style.fontFamily != CoreFontFamily.mono &&
          spacing == tracking.atSize(drawn);
      return style.copyWith(
        // Divided before it is multiplied, so CoUI's own role — whose size IS
        // the size it is drawn at — comes out as exactly the table's number.
        fontSize: size / drawn * stepped,
        lineHeightPx: box == null ? null : box / drawn * stepped,
        letterSpacing: followsRule ? tracking.atSize(stepped) : null,
      );
    });
  }

  /// A copy of this scale with [transform] applied to [roles] and every
  /// other role as it is.
  CoreTypography _mapRoles(
    Iterable<CoreTextStyleToken> roles,
    CoreTextStyle Function(CoreTextStyleToken token, CoreTextStyle style)
    transform,
  ) {
    final selected = roles.toSet();
    CoreTextStyle pick(CoreTextStyleToken token) {
      final style = token.read(this);
      return selected.contains(token) ? transform(token, style) : style;
    }

    return CoreTypography(
      displayLarge: pick(CoreTextStyles.displayLarge),
      displayMedium: pick(CoreTextStyles.displayMedium),
      displaySmall: pick(CoreTextStyles.displaySmall),
      headlineLarge: pick(CoreTextStyles.headlineLarge),
      headlineMedium: pick(CoreTextStyles.headlineMedium),
      headlineSmall: pick(CoreTextStyles.headlineSmall),
      titleLarge: pick(CoreTextStyles.titleLarge),
      titleMedium: pick(CoreTextStyles.titleMedium),
      titleSmall: pick(CoreTextStyles.titleSmall),
      bodyLarge: pick(CoreTextStyles.bodyLarge),
      bodyMedium: pick(CoreTextStyles.bodyMedium),
      bodySmall: pick(CoreTextStyles.bodySmall),
      bodyXs: pick(CoreTextStyles.bodyXs),
      labelXl2: pick(CoreTextStyles.labelXl2),
      labelXl: pick(CoreTextStyles.labelXl),
      labelLarge: pick(CoreTextStyles.labelLarge),
      labelMedium: pick(CoreTextStyles.labelMedium),
      labelSmall: pick(CoreTextStyles.labelSmall),
      labelXs: pick(CoreTextStyles.labelXs),
      codeXs: pick(CoreTextStyles.codeXs),
      codeSm: pick(CoreTextStyles.codeSm),
      codeMd: pick(CoreTextStyles.codeMd),
    );
  }

  /// Resolves a [CoreTextStyle] against this typography scale.
  ///
  /// Token references (`textStyle.token != null`) are materialised by
  /// looking up the matching slot; raw `CoreTextStyle` values
  /// (`token == null`) pass through unchanged. The optional `color` set
  /// alongside the token wrapper survives the lookup — it is overlaid
  /// onto the resolved slot.
  ///
  /// Mirrors `CoreColorScheme.resolve` for typography (Epic #1601 PoC).
  CoreTextStyle resolve(CoreTextStyle textStyle) {
    final token = textStyle.token;
    if (token == null) return textStyle;
    final slot = token.read(this);
    final overlayColor = textStyle.color;
    return overlayColor == null ? slot : slot.copyWith(color: overlayColor);
  }

  // Every role is compared. A theme axis hands the frameworks a new scale
  // and they rebuild only when it is unequal to the old one, so a role left
  // out here is a role whose change never reaches the screen; and identity
  // alone would restart a theme animation on every build that derives a
  // value-equal scale (`atTier` does, each time it steps the headings).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTypography &&
          displayLarge == other.displayLarge &&
          displayMedium == other.displayMedium &&
          displaySmall == other.displaySmall &&
          headlineLarge == other.headlineLarge &&
          headlineMedium == other.headlineMedium &&
          headlineSmall == other.headlineSmall &&
          titleLarge == other.titleLarge &&
          titleMedium == other.titleMedium &&
          titleSmall == other.titleSmall &&
          bodyLarge == other.bodyLarge &&
          bodyMedium == other.bodyMedium &&
          bodySmall == other.bodySmall &&
          bodyXs == other.bodyXs &&
          labelXl2 == other.labelXl2 &&
          labelXl == other.labelXl &&
          labelLarge == other.labelLarge &&
          labelMedium == other.labelMedium &&
          labelSmall == other.labelSmall &&
          labelXs == other.labelXs &&
          codeXs == other.codeXs &&
          codeSm == other.codeSm &&
          codeMd == other.codeMd;

  @override
  int get hashCode => Object.hashAll([
    displayLarge,
    displayMedium,
    displaySmall,
    headlineLarge,
    headlineMedium,
    headlineSmall,
    titleLarge,
    titleMedium,
    titleSmall,
    bodyLarge,
    bodyMedium,
    bodySmall,
    bodyXs,
    labelXl2,
    labelXl,
    labelLarge,
    labelMedium,
    labelSmall,
    labelXs,
    codeXs,
    codeSm,
    codeMd,
  ]);
}
