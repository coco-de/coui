import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform action area pinned to the bottom of a screen — the
/// one or two buttons that finish a flow, and an optional short note above
/// them.
///
/// Uses [CoreBottomActionBarContract] from `coui_core`, so the Web
/// `BottomActionBar` takes the same named properties. The bar owns the
/// arrangement, the padding, the hairline above it ([showDivider]) and the
/// filled surface; the buttons are the caller's own and keep their own size
/// and look. Each action gets the full width of its cell, so a `Button`
/// inside needs no `expanded` of its own.
///
/// The [layout] stacks the actions in one column (the primary action on
/// top) or sets them in one row of equal-width cells (the secondary action
/// first, the primary action last). The note sits above either.
///
/// The bottom padding is added to the device's bottom safe area: the
/// surface paints under the home indicator and the actions sit above it.
/// Colours, padding, spacing, the hairline and the note's text style flow
/// from the widget → `CoreComponentTheme.bottomActionBar` → design system
/// defaults ([CoreBottomActionBarStyle]).
///
/// ```dart
/// BottomActionBar(
///   description: Text('By continuing you agree to the terms.'),
///   primaryAction: Button(size: .xl, child: Text('Register')),
///   secondaryAction: Button(variant: .ghost, child: Text('Not now')),
/// )
/// ```
///
/// surface:behind — the shell stacks this bar over a body that scrolls
/// beneath it.
///
/// surface:functional — the bar groups the actions that finish a flow above
/// the page it is docked to.
class BottomActionBar extends StatelessWidget
    implements CoreBottomActionBarContract<Widget> {
  /// Creates a [BottomActionBar].
  const BottomActionBar({
    required this.primaryAction,
    super.key,
    this.secondaryAction,
    this.description,
    this.summaryLabel,
    this.summaryValue,
    this.layout = CoreBottomActionBarLayout.defaultLayout,
    this.showDivider = CoreBottomActionBarContract.defaultShowDivider,
    this.bottomActionBarStyle,
  });

  @override
  final Widget primaryAction;

  @override
  final Widget? secondaryAction;

  @override
  final Widget? description;

  @override
  final Widget? summaryLabel;

  @override
  final Widget? summaryValue;

  @override
  final CoreBottomActionBarLayout layout;

  @override
  final bool showDivider;

  @override
  final CoreBottomActionBarStyle? bottomActionBarStyle;

  /// Returns a copy of this bar with the supplied non-null fields
  /// overridden.
  BottomActionBar copyWith({
    Key? key,
    Widget? primaryAction,
    Widget? secondaryAction,
    Widget? description,
    Widget? summaryLabel,
    Widget? summaryValue,
    CoreBottomActionBarLayout? layout,
    bool? showDivider,
    CoreBottomActionBarStyle? bottomActionBarStyle,
  }) {
    return BottomActionBar(
      key: key ?? this.key,
      primaryAction: primaryAction ?? this.primaryAction,
      secondaryAction: secondaryAction ?? this.secondaryAction,
      description: description ?? this.description,
      summaryLabel: summaryLabel ?? this.summaryLabel,
      summaryValue: summaryValue ?? this.summaryValue,
      layout: layout ?? this.layout,
      showDivider: showDivider ?? this.showDivider,
      bottomActionBarStyle: bottomActionBarStyle ?? this.bottomActionBarStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveBottomActionBar(
      context,
      bottomActionBarStyle: bottomActionBarStyle,
    );

    // The summary's column (caption over figure), at its own width — both
    // summary arrangements draw the same one.
    final summary = summaryLabel != null || summaryValue != null
        ? Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              if (summaryLabel case final summaryLabel?)
                DefaultTextStyle(
                  style: resolved.summaryLabelTextStyle,
                  child: summaryLabel,
                ),
              if (summaryValue case final summaryValue?)
                DefaultTextStyle(
                  style: resolved.summaryValueTextStyle,
                  child: summaryValue,
                ),
            ],
          )
        : null;

    final actions = switch (layout) {
      .vertical => [primaryAction, ?secondaryAction],
      .horizontal => [
        // The cross axis stays at the `Row` default, the centre: two actions
        // of different heights sit on the same centre line. The Web twin
        // states `items-center` because a flex row stretches its cells by
        // default — the two must not be left to differ.
        Row(
          spacing: resolved.spacing,
          children: [
            if (secondaryAction case final secondaryAction?)
              Expanded(child: secondaryAction),
            Expanded(child: primaryAction),
          ],
        ),
      ],
      // The secondary action keeps its own width and the primary action
      // takes the rest. The Web twin's secondary cell does not shrink.
      .weighted || .icon => [
        Row(
          spacing: resolved.spacing,
          children: [
            ?secondaryAction,
            Expanded(child: primaryAction),
          ],
        ),
      ],
      // The summary keeps its own width, the primary action takes the rest;
      // the secondary action is not drawn.
      .summary => [
        Row(
          spacing: resolved.spacing,
          children: [
            ?summary,
            Expanded(child: primaryAction),
          ],
        ),
      ],
      // The summary takes the rest of the row and the primary action keeps
      // its own width at the end — a lone primary action still sits at the
      // end. The Web twin's summary cell grows the same way.
      .summaryCompact => [
        Row(
          spacing: resolved.spacing,
          children: [
            Expanded(
              child: Align(alignment: .centerStart, child: summary),
            ),
            primaryAction,
          ],
        ),
      ],
    };

    // The safe area is inside the filled box so the surface paints under
    // the home indicator. Only the bottom edge: the bar spans the screen
    // and the sides' insets are the caller's page padding, not the bar's.
    //
    // `Container` rather than a bare `DecoratedBox`: the hairline's width
    // joins the padding, so it takes layout height the way the Web
    // twin's `border-top` does.
    Widget bar = Container(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        // `BorderSide(width: 0)` paints a hairline in Flutter while
        // `border-top-width: 0` draws nothing on Web, so a zero width states
        // no border at all.
        border: showDivider && resolved.dividerWidth > 0
            ? Border(
                top: BorderSide(
                  color: resolved.dividerColor,
                  width: resolved.dividerWidth,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: resolved.padding,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: resolved.spacing,
            children: [
              if (description case final description?)
                DefaultTextStyle(
                  style: resolved.descriptionTextStyle,
                  textAlign: resolved.descriptionTextAlign,
                  child: description,
                ),
              ...actions,
            ],
          ),
        ),
      ),
    );

    // A fill-less bar handed a material would stack a backdrop pass over
    // nothing, and a style with no material draws no pass at all — the
    // default tree is the plain box.
    final blur = resolved.surfaceBlur;
    if (((blur != null && blur > 0) || resolved.surfaceSheen != null) &&
        resolved.backgroundColor.a > 0) {
      bar = SurfaceBlur(
        surfaceBlur: blur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        // The active material's bend. Every surface that draws the material
        // draws all of it — the frost and the chroma without the bend is a
        // blurred panel, not glass.
        refraction: resolved.refraction,
        child: bar,
      );
    }

    return CoUISemantics(role: .group, container: true, child: bar);
  }
}

/// Chain sugar for merging a [CoreBottomActionBarStyle] patch into
/// [BottomActionBar.bottomActionBarStyle] without hand-reconstructing every
/// field. Mirrors the Web `BottomActionBar.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBottomActionBarStyle.merge` right-side-wins semantics).
extension BottomActionBarStyleChain on BottomActionBar {
  /// Returns a copy of this [BottomActionBar] with [patch] merged into
  /// [bottomActionBarStyle] (patch fields win on conflict).
  BottomActionBar withStyle(CoreBottomActionBarStyle patch) => copyWith(
    bottomActionBarStyle:
        (bottomActionBarStyle ?? const CoreBottomActionBarStyle()).merge(patch),
  );
}
