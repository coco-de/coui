import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/bottom_action_bar/bottom_action_bar_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform bottom action bar — the one or two buttons that
/// finish a flow (register, pay, confirm), pinned to the bottom of a screen,
/// with an optional short note above them.
///
/// Uses [CoreBottomActionBarContract] from `coui_core`, so the Flutter
/// `BottomActionBar` takes the same named properties. The bar owns the
/// arrangement, the padding, the hairline above it and the surface; the
/// actions are the caller's own `Button`s and keep their own size and look.
/// Each action is given the full width of its cell, so a `Button` inside
/// needs no `expanded` of its own.
///
/// [layout] stacks the actions in one column
/// ([CoreBottomActionBarLayout.vertical], the primary on top) or sets them in
/// one row of equal-width cells ([CoreBottomActionBarLayout.horizontal], the
/// secondary first and the primary last — a lone primary fills the row).
///
/// The bottom padding is added to the device's bottom safe area (the home
/// indicator): the surface paints under it and the actions sit above it.
/// Where the page declares no inset the safe area is zero and nothing is
/// added. The left, right and top edges are not inset.
///
/// ```dart
/// BottomActionBar(
///   description: const Text('You will not be charged yet.'),
///   primaryAction: Button(child: const Text('Reserve')),
///   secondaryAction: Button(
///     variant: .ghost,
///     child: const Text('Cancel'),
///   ),
/// )
/// ```
///
/// The root is a `<div role="group">` with no accessible name of its own —
/// it is a region of controls, not a landmark. A page that wants it named
/// passes `attributes: {'aria-label': '…'}`.
///
/// surface:behind — the shell stacks this bar over a body that scrolls
/// beneath it.
/// surface:functional — the bar floats the screen's finishing actions over
/// the page.
class BottomActionBar extends UiComponent
    implements CoreBottomActionBarContract<Component> {
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component primaryAction;

  @override
  final Component? secondaryAction;

  @override
  final Component? description;

  @override
  final Component? summaryLabel;

  @override
  final Component? summaryValue;

  @override
  final CoreBottomActionBarLayout layout;

  @override
  final bool showDivider;

  @override
  final CoreBottomActionBarStyle? bottomActionBarStyle;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', CoreSemanticRole.group.ariaRole);
  }

  @override
  BottomActionBar copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? primaryAction,
    Component? secondaryAction,
    Component? description,
    Component? summaryLabel,
    Component? summaryValue,
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
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveBottomActionBar(
      context,
      layout: layout,
      showDivider: showDivider,
      bottomActionBarStyle: bottomActionBarStyle,
    );

    // One equal-width cell of the horizontal row.
    Component cell(Component action) => div(
      [action],
      classes: resolved.cell.className,
      styles: resolved.cell.inlineStyles,
    );

    // The summary's column (caption over figure), at its own width — both
    // summary arrangements draw the same one.
    final summary = summaryLabel != null || summaryValue != null
        ? div(
            [
              if (summaryLabel case final summaryLabel?)
                div(
                  [summaryLabel],
                  classes: resolved.summaryLabel.className,
                  styles: resolved.summaryLabel.inlineStyles,
                ),
              if (summaryValue case final summaryValue?)
                div(
                  [summaryValue],
                  classes: resolved.summaryValue.className,
                  styles: resolved.summaryValue.inlineStyles,
                ),
            ],
            classes: resolved.summary.className,
            styles: resolved.summary.inlineStyles,
          )
        : null;

    return div(
      [
        if (description case final description?)
          div(
            [description],
            classes: resolved.description.className,
            styles: resolved.description.inlineStyles,
          ),
        div(
          // The DOM order is the Flutter child order, so the tab order
          // follows the visual order on both platforms.
          switch (layout) {
            .vertical => [primaryAction, ?secondaryAction],
            .horizontal => [
              if (secondaryAction case final secondaryAction?)
                cell(secondaryAction),
              cell(primaryAction),
            ],
            // The secondary action keeps its own width, the primary action
            // fills the rest (the Flutter twin's `Row` with an `Expanded`).
            .weighted || .icon => [
              if (secondaryAction case final secondaryAction?)
                div(
                  [secondaryAction],
                  classes: resolved.fixedCell.className,
                  styles: resolved.fixedCell.inlineStyles,
                ),
              cell(primaryAction),
            ],
            // The summary keeps its own width, the primary action fills the
            // rest; the secondary action is not drawn.
            .summary => [
              ?summary,
              cell(primaryAction),
            ],
            // The summary takes the rest of the row, the primary action keeps
            // its own width at the end (the Flutter twin's `Expanded` summary).
            // The grown cell is drawn even without a summary, so a lone
            // primary action still sits at the end.
            .summaryCompact => [
              div(
                [?summary],
                classes: resolved.cell.className,
                styles: resolved.cell.inlineStyles,
              ),
              div(
                [primaryAction],
                classes: resolved.fixedCell.className,
                styles: resolved.fixedCell.inlineStyles,
              ),
            ],
          },
          classes: resolved.actions.className,
          styles: resolved.actions.inlineStyles,
        ),
      ],
      id: id,
      classes: mergeClasses(resolved.root.className, classes),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }
}

/// Chain sugar for merging a [CoreBottomActionBarStyle] patch into
/// [BottomActionBar.bottomActionBarStyle] without hand-reconstructing every
/// field. Mirrors the Flutter `BottomActionBar.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBottomActionBarStyle.merge` right-side-wins semantics).
extension BottomActionBarStyleChain on BottomActionBar {
  /// Sets the content padding.
  BottomActionBar contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreBottomActionBarStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  BottomActionBar backgroundColor(CoreColor value) =>
      withStyle(CoreBottomActionBarStyle(backgroundColor: value));

  /// Returns a copy of this [BottomActionBar] with [patch] merged into
  /// [bottomActionBarStyle] (patch fields win on conflict).
  BottomActionBar withStyle(CoreBottomActionBarStyle patch) => copyWith(
    bottomActionBarStyle:
        (bottomActionBarStyle ?? const CoreBottomActionBarStyle()).merge(
          patch,
        ),
  );
}
