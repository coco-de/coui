/// Per-instance chrome style for `TextBlock`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing the box chrome of a `TextBlock`.
///
/// A text block normally renders a semantic text element with a
/// typography preset and no surrounding box. Two element roles do
/// carry chrome — `blockquote` (a left accent border + indent) and
/// `pre` (an inline-code surface box) — and the dimensional values
/// for that chrome live here so the Flutter and Web implementations
/// share a single source of truth. The same two roles also state their
/// own text — typography role and colour — through [blockQuoteTextStyle]
/// and [inlineCodeTextStyle], so what the text looks like inside the box
/// is as much a design-system default as the box itself.
///
/// Variant-independent design-system defaults live as `static const`
/// on this class (Epic #1415 Phase 6f + #1696 Phase 6) — Flutter and
/// Web reference the same `CoreTextBlockStyle.defaultX` so the two
/// platforms cannot silently diverge. The text block has no visual
/// variant, so there is no `defaultsByVariant` map.
///
/// ```text
/// design system default (CoreTextBlockStyle.defaultX)
///   → widget chrome usage (Flutter `_BlockQuote` / `_InlineCodeBox`,
///                          Web `quote` / `inlineCode` presets)
/// ```
@immutable
class CoreTextBlockStyle implements CoreStyle<CoreTextBlockStyle> {
  /// Creates a [CoreTextBlockStyle].
  const CoreTextBlockStyle({
    this.blockQuoteBorderColor,
    this.blockQuoteBorderWidth,
    this.blockQuotePadding,
    this.blockQuoteTextStyle,
    this.inlineCodeBackgroundColor,
    this.inlineCodeRadius,
    this.inlineCodePadding,
    this.inlineCodeTextStyle,
  });

  // ── Design-system defaults (Epic #1415 Phase 6f + #1696 Phase 6) ──
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web `TextBlock` chrome wrappers. The text block
  // has no visual variant so there is no `defaultsByVariant` map.

  /// Default left accent-border colour for the `blockquote` element —
  /// the `outlineVariant` token, the quiet divider colour: the rule marks
  /// the quote without competing with the text beside it. Flutter resolves
  /// this token through `scheme.resolve(...).toValue()`; Web emits the
  /// token as `rgb(var(--coui-outline-variant))`. Single source of truth so
  /// the two platforms cannot diverge.
  static const CoreColor defaultBlockQuoteBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default left accent-border stroke width for the `blockquote`
  /// element (3 logical px).
  static const double defaultBlockQuoteBorderWidth = CoreStrokeWidth.stroke3;

  /// Default left indent between the `blockquote` accent border and
  /// its text — `CoreSpace.space16` on the start side only (Markdown
  /// blockquote left-indent semantic). Directional because the indent
  /// is a statement about the margin the text starts at, which is the
  /// right in an Arabic locale. Resolvers / chrome wrappers fall back to
  /// this constant when neither the widget nor theme supplies a
  /// [blockQuotePadding].
  static const CoreEdgeInsets defaultBlockQuotePadding =
      CoreEdgeInsets.directional(start: CoreSpace.space16);

  /// Default text of the `blockquote` element — the `bodyMedium` role in
  /// the muted `onSurfaceVariant` foreground. The role and the colour are
  /// one statement: a quote reads one step quieter than the paragraph
  /// around it, and a role stated without its colour would leave that
  /// colour to whatever the surroundings happen to inherit.
  static const CoreTextStyle defaultBlockQuoteTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default surface-fill colour of the `pre` inline-code box — the
  /// `surfaceContainer` token (mirrors Web's `bg-surface-container`).
  /// Flutter resolves this token through `scheme.resolve(...).toValue()`;
  /// Web emits the token class. Single source of truth shared by both
  /// platforms.
  static const CoreColor defaultInlineCodeBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default foreground colour of the `muted` / `lead` typography
  /// presets — the muted `onSurfaceVariant` token. Both platforms route
  /// the preset text colour through this constant (Flutter
  /// `scheme.resolve(...).toValue()`, Web `text-{onSurfaceVariant}`) so
  /// the muted foreground stays a single source of truth.
  static const CoreColor defaultMutedForegroundColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default corner radius of the `pre` inline-code surface box
  /// (4 logical px). Mirrors Web's `rounded`.
  static const double defaultInlineCodeRadius = CoreRadius.radius4;

  /// Default inner padding of the `pre` inline-code surface box —
  /// `CoreSpace.space6` horizontally / 1 logical px vertically. The vertical
  /// inset is a component value, carried by the numeric inset path: the
  /// spacing ladder has no 1px step.
  /// Symmetric on both axes, so it reads the same in either reading
  /// direction and needs no directional spelling.
  static const CoreEdgeInsets defaultInlineCodePadding =
      CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space6,
        vertical: 1,
      );

  /// Default text of the `pre` inline-code box — the fixed-width `codeMd`
  /// role in the `onSurface` foreground. The monospace family, the 13px
  /// size and the fixed line box all come with the role, so the code reads
  /// on the same grid as every other code surface instead of being a body
  /// role with a family laid over it.
  static const CoreTextStyle defaultInlineCodeTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeMd,
    color: CoreColor.token(CoreColors.onSurface),
  );

  // ── Text-block chrome (flat) ─────────────────────

  /// Left accent-border colour override for `blockquote`. `null` defers
  /// to [defaultBlockQuoteBorderColor].
  final CoreColor? blockQuoteBorderColor;

  /// Left accent-border stroke width override for `blockquote`
  /// (logical px).
  final double? blockQuoteBorderWidth;

  /// Left indent between the `blockquote` accent border and its text.
  /// Defaults to the start side only ([defaultBlockQuotePadding]); you can
  /// pass a four-side `CoreEdgeInsets` to pad the other sides too.
  final CoreEdgeInsets? blockQuotePadding;

  /// Text override for the `blockquote` element — typography role and
  /// colour together. `null` defers to [defaultBlockQuoteTextStyle]; a
  /// partial style (a colour alone, a weight alone) is laid over the
  /// default, so the role the default states is kept.
  final CoreTextStyle? blockQuoteTextStyle;

  /// Surface-fill colour override of the `pre` inline-code box. `null`
  /// defers to [defaultInlineCodeBackgroundColor].
  final CoreColor? inlineCodeBackgroundColor;

  /// Corner radius override of the `pre` inline-code surface box
  /// (logical px).
  final double? inlineCodeRadius;

  /// Inner padding override inside the `pre` inline-code surface box.
  final CoreEdgeInsets? inlineCodePadding;

  /// Text override for the `pre` inline-code box — typography role and
  /// colour together. `null` defers to [defaultInlineCodeTextStyle]; a
  /// partial style (a colour alone, a weight alone) is laid over the
  /// default, so the role the default states is kept.
  final CoreTextStyle? inlineCodeTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreTextBlockStyle merge(CoreTextBlockStyle? other) {
    if (other == null) return this;
    return CoreTextBlockStyle(
      blockQuoteBorderColor:
          other.blockQuoteBorderColor ?? blockQuoteBorderColor,
      blockQuoteBorderWidth:
          other.blockQuoteBorderWidth ?? blockQuoteBorderWidth,
      blockQuotePadding: other.blockQuotePadding ?? blockQuotePadding,
      blockQuoteTextStyle: _mergeText(
        blockQuoteTextStyle,
        other.blockQuoteTextStyle,
      ),
      inlineCodeBackgroundColor:
          other.inlineCodeBackgroundColor ?? inlineCodeBackgroundColor,
      inlineCodeRadius: other.inlineCodeRadius ?? inlineCodeRadius,
      inlineCodePadding: other.inlineCodePadding ?? inlineCodePadding,
      inlineCodeTextStyle: _mergeText(
        inlineCodeTextStyle,
        other.inlineCodeTextStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTextBlockStyle copyWith({
    CoreColor? blockQuoteBorderColor,
    double? blockQuoteBorderWidth,
    CoreEdgeInsets? blockQuotePadding,
    CoreTextStyle? blockQuoteTextStyle,
    CoreColor? inlineCodeBackgroundColor,
    double? inlineCodeRadius,
    CoreEdgeInsets? inlineCodePadding,
    CoreTextStyle? inlineCodeTextStyle,
  }) {
    return CoreTextBlockStyle(
      blockQuoteBorderColor:
          blockQuoteBorderColor ?? this.blockQuoteBorderColor,
      blockQuoteBorderWidth:
          blockQuoteBorderWidth ?? this.blockQuoteBorderWidth,
      blockQuotePadding: blockQuotePadding ?? this.blockQuotePadding,
      blockQuoteTextStyle: blockQuoteTextStyle ?? this.blockQuoteTextStyle,
      inlineCodeBackgroundColor:
          inlineCodeBackgroundColor ?? this.inlineCodeBackgroundColor,
      inlineCodeRadius: inlineCodeRadius ?? this.inlineCodeRadius,
      inlineCodePadding: inlineCodePadding ?? this.inlineCodePadding,
      inlineCodeTextStyle: inlineCodeTextStyle ?? this.inlineCodeTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextBlockStyle &&
          runtimeType == other.runtimeType &&
          blockQuoteBorderColor == other.blockQuoteBorderColor &&
          blockQuoteBorderWidth == other.blockQuoteBorderWidth &&
          blockQuotePadding == other.blockQuotePadding &&
          blockQuoteTextStyle == other.blockQuoteTextStyle &&
          inlineCodeBackgroundColor == other.inlineCodeBackgroundColor &&
          inlineCodeRadius == other.inlineCodeRadius &&
          inlineCodePadding == other.inlineCodePadding &&
          inlineCodeTextStyle == other.inlineCodeTextStyle;

  @override
  int get hashCode => Object.hash(
    blockQuoteBorderColor,
    blockQuoteBorderWidth,
    blockQuotePadding,
    blockQuoteTextStyle,
    inlineCodeBackgroundColor,
    inlineCodeRadius,
    inlineCodePadding,
    inlineCodeTextStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
