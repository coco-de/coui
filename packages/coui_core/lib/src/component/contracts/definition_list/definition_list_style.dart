/// Per-instance style for `DefinitionList`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/definition_list/core_definition_layout.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `DefinitionList` should render.
///
/// Platform-neutral. Semantic / content fields (`items`, `layout`,
/// `numeric`, `mono`) stay on the widget; everything spatial or
/// typographic flows through here.
///
/// The design-system defaults are a table keyed by the layout —
/// [defaultsByLayout] — because the three layouts do not ask the same
/// thing of the type scale: a stacked term is a caption above its value,
/// while a column or inline term sits beside it.
///
/// Two gaps rather than a CSS `row-gap` / `column-gap` pair, because
/// which CSS axis each one lands on depends on the layout: in
/// `CoreDefinitionLayout.stacked` a term and its own description are
/// stacked vertically *and* so are two neighbouring entries, so a single
/// axis-named gap could not tell the two distances apart. [entrySpacing] and
/// [pairSpacing] name the *relationship* instead, and each layout maps them
/// onto its own axes.
@immutable
class CoreDefinitionListStyle implements CoreStyle<CoreDefinitionListStyle> {
  /// Creates a [CoreDefinitionListStyle].
  const CoreDefinitionListStyle({
    this.entrySpacing,
    this.pairSpacing,
    this.termTextStyle,
    this.descriptionTextStyle,
    this.monoDescriptionTextStyle,
    this.termWidth,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default `<dd>` typography when the list is built with `mono: true` —
  /// the `code-sm` role (12px, a fixed 21px line box, Geist Mono) in the
  /// primary foreground.
  ///
  /// It stands in for the layout row's `descriptionTextStyle` rather than
  /// layering over it, because the role carries its own size, weight and
  /// line box; a caller's [descriptionTextStyle] then merges over it the
  /// way it merges over the row, and [monoDescriptionTextStyle] over both.
  static const CoreTextStyle defaultMonoDescriptionTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.codeSm,
        color: CoreColor.token(CoreColors.onSurface),
      );

  /// The design-system default for each [CoreDefinitionLayout] — one
  /// complete row per layout, so `defaultsByLayout[layout]!` always has the
  /// four fields below non-null.
  ///
  /// * `stacked` — the term is a caption over its value, one step down the
  ///   type scale (`label-small` 12 against `label-medium` 13), with the
  ///   pair held tight (2) and the entries held apart (14).
  /// * `columns` — term and value sit side by side in the same
  ///   `label-medium` 13 / 500. Position (the column) and colour tell them
  ///   apart rather than size; the pair gap is 8 and the row gap is 24.
  /// * `inline` — the same roles as `columns`, run on one wrapping line
  ///   with a 16 gap between pairs.
  ///
  /// The term colour is `onSurfaceSubtle` in every row, written in each
  /// row on purpose: it is the one value here that is a colour decision
  /// rather than a size or a distance, and it changes in one place if the
  /// muted slot does. A term is meta text that no state layer ever washes,
  /// so it reads the subtle slot rather than `onSurfaceVariant`.
  static const Map<CoreDefinitionLayout, CoreDefinitionListStyle>
  defaultsByLayout = {
    CoreDefinitionLayout.stacked: CoreDefinitionListStyle(
      entrySpacing: CoreSpace.space14,
      pairSpacing: CoreSpace.space2,
      termTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
      descriptionTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
    CoreDefinitionLayout.columns: CoreDefinitionListStyle(
      entrySpacing: CoreSpace.space24,
      pairSpacing: CoreSpace.space8,
      termTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
      descriptionTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
    CoreDefinitionLayout.inline: CoreDefinitionListStyle(
      entrySpacing: CoreSpace.space16,
      pairSpacing: CoreSpace.space8,
      termTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ),
      descriptionTextStyle: CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ),
    ),
  };

  // ─── Fields ─────────────────────────────────────────────────────

  /// Distance between one term / description pair and the next, in
  /// logical pixels.
  ///
  /// Maps to `row-gap` in `CoreDefinitionLayout.columns`, to the
  /// `<dt>`'s leading block margin in `stacked`, and to the `<dt>`'s
  /// leading inline margin in `inline`.
  ///
  /// The default is `defaultsByLayout[layout].entrySpacing` — 14 stacked,
  /// 24 in columns, 16 inline. It differs per layout, so there is no single
  /// scalar default.
  final double? entrySpacing;

  /// Distance between a term and its own description, in logical pixels.
  ///
  /// Maps to `column-gap` in `CoreDefinitionLayout.columns`, and to the
  /// `<dd>`'s leading block / inline margin in `stacked` / `inline`.
  ///
  /// The default is `defaultsByLayout[layout].pairSpacing` — 2 stacked, 8
  /// in columns and inline. It differs per layout, so there is no single
  /// scalar default.
  final double? pairSpacing;

  /// `<dt>` typography override. Layered over the layout row of
  /// [defaultsByLayout] — a caller who sets only `fontWeight` keeps the
  /// default role and colour. The default differs per layout (`label-small`
  /// stacked, `label-medium` in columns and inline), so there is no single
  /// scalar default.
  final CoreTextStyle? termTextStyle;

  /// `<dd>` typography override. Layered over the layout row of
  /// [defaultsByLayout] (or [defaultMonoDescriptionTextStyle] when the list
  /// is `mono`) on the same terms as [termTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// `<dd>` typography override that applies only when the list is `mono`.
  /// Layered over [defaultMonoDescriptionTextStyle] and then over any
  /// [descriptionTextStyle], so a theme can recolour every description while
  /// a mono list alone changes its code weight.
  final CoreTextStyle? monoDescriptionTextStyle;

  /// Fixed width of the term column, in logical pixels — only
  /// `CoreDefinitionLayout.columns` reads it; `stacked` and `inline` ignore
  /// it.
  ///
  /// No `default*` by design — absence means `max-content`: the column is as
  /// wide as its widest term, and a long term squeezes the description
  /// column. Setting a width holds the column there, so descriptions start
  /// at the same edge across lists whose terms differ.
  final double? termWidth;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The nested [CoreTextStyle]
  /// slots merge recursively, so an override of one typographic field
  /// does not drop the rest.
  @override
  CoreDefinitionListStyle merge(CoreDefinitionListStyle? other) {
    if (other == null) return this;
    return CoreDefinitionListStyle(
      entrySpacing: other.entrySpacing ?? entrySpacing,
      pairSpacing: other.pairSpacing ?? pairSpacing,
      termTextStyle: _mergeText(termTextStyle, other.termTextStyle),
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
      monoDescriptionTextStyle: _mergeText(
        monoDescriptionTextStyle,
        other.monoDescriptionTextStyle,
      ),
      termWidth: other.termWidth ?? termWidth,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreDefinitionListStyle copyWith({
    double? entrySpacing,
    double? pairSpacing,
    CoreTextStyle? termTextStyle,
    CoreTextStyle? descriptionTextStyle,
    CoreTextStyle? monoDescriptionTextStyle,
    double? termWidth,
  }) {
    return CoreDefinitionListStyle(
      entrySpacing: entrySpacing ?? this.entrySpacing,
      pairSpacing: pairSpacing ?? this.pairSpacing,
      termTextStyle: termTextStyle ?? this.termTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      monoDescriptionTextStyle:
          monoDescriptionTextStyle ?? this.monoDescriptionTextStyle,
      termWidth: termWidth ?? this.termWidth,
    );
  }

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDefinitionListStyle &&
          runtimeType == other.runtimeType &&
          entrySpacing == other.entrySpacing &&
          pairSpacing == other.pairSpacing &&
          termTextStyle == other.termTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle &&
          monoDescriptionTextStyle == other.monoDescriptionTextStyle &&
          termWidth == other.termWidth;

  @override
  int get hashCode => Object.hash(
    entrySpacing,
    pairSpacing,
    termTextStyle,
    descriptionTextStyle,
    monoDescriptionTextStyle,
    termWidth,
  );
}
