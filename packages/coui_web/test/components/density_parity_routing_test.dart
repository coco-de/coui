// A density re-maps the `--coui-space-*` variables on Web, so on this
// platform "goes through a spacing variable" and "moves with the density"
// are the same statement. The Flutter twin decides which values move at its
// own conversion points — `theme.geometry.space` for spacing doubles, the
// geometry-aware `CoreEdgeInsets.toValue` for insets — and leaves positions,
// sizes, drawn geometry and the gaps that Dart arithmetic depends on where
// they are.
//
// Each case below reads back what Web emits for one value and states which
// side of that line it is on. A value that drifts to the other side keeps
// rendering identically at the standard density, so nothing else here would
// notice — only the compact / spacious page would come apart from Flutter.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/multi_answer_card/multi_answer_card_style.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_style.dart';
import 'package:coui_web/src/components/layout/accordion/accordion_style.dart';
import 'package:coui_web/src/components/layout/gap/gap_style.dart';
import 'package:coui_web/src/components/layout/scaffold/scaffold_style.dart';
import 'package:coui_web/src/components/layout/tree/tree_style.dart';
import 'package:coui_web/src/components/layout/window/window_style.dart';
import 'package:coui_web/src/components/menu/menu/menu_style.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_style.dart';
import 'package:coui_web/src/components/overlay/toast/toast_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

/// Runs [read] against a themed build context and returns what it read.
T _read<T>(ComponentTester tester, T Function(BuildContext context) read) {
  late T value;
  pumpWithTheme(tester, _ContextCapture((context) => value = read(context)));
  return value;
}

String _prop(WebElementChrome chrome, String property) =>
    chrome.inlineStyles!.properties[property]!;

/// The value names a spacing variable — a density moves it.
final Matcher _moves = contains('var(--coui-space-');

/// The value is a literal length — no density reaches it.
final Matcher _stays = allOf(
  isNot(contains('var(--coui-space-')),
  contains('rem'),
);

void main() {
  group('moves with the density — the Flutter twin bends it', () {
    testComponents('a Gap spans its size through the spacing variable', (
      tester,
    ) async {
      final gap = _read(tester, resolveGap);
      final maxGap = _read(tester, resolveMaxGap);
      final sliverGap = _read(tester, resolveSliverGap);

      const size = CoreGapStyle.defaultSize;
      expect(_prop(gap.root, 'flex-basis'), spaceCss(size));
      expect(_prop(gap.root, 'flex-basis'), _moves);
      expect(_prop(sliverGap.root, 'flex-basis'), spaceCss(size));
      // The cap is the same spacing value as the basis — moved together.
      expect(_prop(maxGap.root, 'flex-basis'), spaceCss(size));
      expect(_prop(maxGap.root, 'max-width'), spaceCss(size));
      expect(_prop(maxGap.root, 'max-height'), spaceCss(size));
    });

    testComponents("a Gap's cross axis is a painted extent and stays", (
      tester,
    ) async {
      final gap = _read(
        tester,
        (context) => resolveGap(
          context,
          gapStyle: const CoreGapStyle(crossAxisExtent: CoreSpace.space16),
        ),
      );

      expect(_prop(gap.root, 'min-height'), _stays);
    });

    testComponents('tree icon and label gaps are spacing', (tester) async {
      final tree = _read(tester, resolveTree);

      expect(
        _prop(tree.iconGap, 'width'),
        spaceCss(CoreTreeStyle.defaultIconGapStyle.size!),
      );
      expect(
        _prop(tree.labelGap, 'width'),
        spaceCss(CoreTreeStyle.defaultLabelGapStyle.size!),
      );
      expect(_prop(tree.labelGap, 'width'), _moves);
    });

    testComponents('scaffold FAB offsets are the sides of an inset', (
      tester,
    ) async {
      final scaffold = _read(
        tester,
        (context) => resolveScaffold(
          context,
          variant: CoreScaffoldVariant.defaultVariant,
          hasSidebar: false,
          floatingHeader: false,
          floatingFooter: false,
          fabLocation: CoreScaffoldFabLocation.endFloat,
        ),
      );

      const padding = CoreScaffoldStyle.defaultFabPadding;
      expect(_prop(scaffold.fab, 'bottom'), spaceCss(padding.bottom));
      expect(_prop(scaffold.fab, 'right'), spaceCss(padding.right));
      expect(_prop(scaffold.fab, 'right'), _moves);
    });

    testComponents('the toast dismiss button sits at its inset', (
      tester,
    ) async {
      final toast = _read(
        tester,
        (context) => resolveToast(
          context,
          variant: CoreToastVariant.defaultVariant,
          dismissible: true,
        ),
      );

      const inset = CoreToastStyle.defaultCloseInset;
      expect(_prop(toast.closeWrapper, 'top'), spaceCss(inset.top));
      expect(_prop(toast.closeWrapper, 'right'), spaceCss(inset.right));
      expect(_prop(toast.closeWrapper, 'top'), _moves);
    });

    testComponents('the slider reserves its padding through the variables', (
      tester,
    ) async {
      final slider = _read(
        tester,
        (context) => resolveSlider(context, enabled: true, ratio: 0),
      );

      const padding = CoreSliderStyle.defaultContainerPadding;
      final minHeight = _prop(slider.root, 'min-height');
      expect(minHeight, contains(spaceCss(padding.top)));
      expect(minHeight, contains(spaceCss(padding.bottom)));
      expect(minHeight, _moves);
    });

    testComponents("the dialog leaves the route's padding on both sides", (
      tester,
    ) async {
      final dialog = _read(tester, resolveDialog);

      expect(
        _prop(dialog.panel, 'width'),
        'calc(100% - 2 * ${spaceCss(CoreDialogStyle.defaultRoutePadding)})',
      );
      expect(dialog.panel.className, isNot(contains('calc(')));
    });

    testComponents('a stated route padding goes through the variable too', (
      tester,
    ) async {
      final dialog = _read(
        tester,
        (context) => resolveDialog(
          context,
          dialogStyle: const CoreDialogStyle(routePadding: CoreSpace.space24),
        ),
      );

      expect(
        _prop(dialog.panel, 'width'),
        'calc(100% - 2 * var(--coui-space-24))',
      );
    });

    testComponents("a stretched dialog's action share spends the actions' "
        'gap through the variable', (tester) async {
      final dialog = _read(
        tester,
        (context) => resolveDialog(
          context,
          actionCount: 2,
          dialogStyle: const CoreDialogStyle(
            actionsLayout: CoreDialogActionsLayout.stretch,
          ),
        ),
      );

      const spacing = CoreDialogStyle.defaultActionSpacing;
      final basis = _prop(dialog.actionCell!, 'flex-basis');
      expect(basis, contains(spaceCss(spacing)));
      expect(basis, _moves);
      // The gap between the cells is the same variable — a density moves
      // the share and the gap together, so the cells still fill the row.
      expect(_prop(dialog.footer, 'column-gap'), spaceCss(spacing));
    });

    testComponents('the window snap bar sizes its groups inside its padding', (
      tester,
    ) async {
      final metrics = _read(tester, resolveWindowMetrics);

      const padding = CoreWindowStyle.defaultSnapBarPadding;
      expect(
        metrics.snapBarContentHeightCss,
        allOf(
          contains(spaceCss(padding.top)),
          contains(spaceCss(padding.bottom)),
        ),
      );
    });
  });

  group('spacing the Flutter twin moves stays on the variables', () {
    testComponents('divider indents', (tester) async {
      final divider = _read(
        tester,
        (context) => resolveDivider(
          context,
          orientation: CoreDividerOrientation.horizontal,
          hasChild: false,
          dividerStyle: const CoreDividerStyle(
            indent: CoreSpace.space8,
            endIndent: CoreSpace.space12,
          ),
        ),
      );

      expect(
        _prop(divider.root, 'margin-inline-start'),
        spaceCss(CoreSpace.space8),
      );
      expect(
        _prop(divider.root, 'margin-inline-end'),
        spaceCss(CoreSpace.space12),
      );
    });

    testComponents('tree depth indent', (tester) async {
      final node = _read(
        tester,
        (context) => resolveTreeNode(
          context: context,
          resolved: resolveTree(context),
          depth: 2,
          selected: false,
          isExpanded: false,
          scopeId: 'probe',
        ),
      );

      expect(
        _prop(node.root, 'padding-left'),
        contains(spaceCss(CoreTreeStyle.defaultIndent)),
      );
    });

    testComponents('menu submenu indent', (tester) async {
      final menu = _read(
        tester,
        (context) => resolveMenu(context, vertical: true),
      );

      expect(
        _prop(menu.submenuIndent, 'padding-inline-start'),
        spaceCss(CoreMenuStyle.defaultSubmenuIndent),
      );
    });

    testComponents('drawer drag-handle inset', (tester) async {
      // The handle is the drawer's — a Swiper draws it through the drawer.
      final drawer = _read(
        tester,
        (context) => resolveDrawer(
          context,
          side: .bottom,
          open: true,
          dragDelta: 0,
        ),
      );

      expect(
        _prop(drawer.handle, 'padding'),
        spaceCss(CoreDrawerStyle.defaultDragHandleInset),
      );
    });

    testComponents('alert title-to-description gap', (tester) async {
      // The gap rides on the description (its top margin), as the Flutter
      // twin pads the description rather than the title.
      final alert = _read(
        tester,
        (context) => resolveAlert(
          context,
          variant: CoreAlertVariant.defaultVariant,
          alertStyle: const CoreAlertStyle(titleBottomMargin: CoreSpace.space8),
        ),
      );

      expect(
        _prop(alert.description, 'margin-top'),
        spaceCss(CoreSpace.space8),
      );
    });

    testComponents('code-snippet pre and line-number margins', (tester) async {
      final snippet = _read(
        tester,
        (context) => resolveCodeSnippet(context, lineCount: 3),
      );

      expect(_prop(snippet.pre, 'margin'), _moves);
      expect(_prop(snippet.lineNumber, 'margin-right'), _moves);
    });

    testComponents('dock horizontal padding', (tester) async {
      final dock = _read(tester, resolveDock);

      final padding = CoreDockStyle.defaultsBySize[CoreDockSize.md]!.padding!;
      expect(_prop(dock.root, 'padding-left'), spaceCss(padding.left));
      expect(_prop(dock.root, 'padding-right'), spaceCss(padding.right));
      expect(_prop(dock.root, 'column-gap'), _moves);
    });

    testComponents('validation badge padding', (tester) async {
      final badge = _read(
        tester,
        (context) => resolveValidationBadge(
          context,
          state: CoreValidationState.valid,
          size: CoreValidationBadgeSize.small,
        ),
      );

      expect(_prop(badge.root, 'padding'), _moves);
    });

    testComponents('frame padding, margin and gap', (tester) async {
      final frame = _read(
        tester,
        (context) => resolveFrame(
          context,
          clipBehavior: CoreClipBehavior.none,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          margin: const CoreEdgeInsets.all(CoreSpace.space8),
          // The gap lays out a flex line, which a direction opens.
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
        ),
      );

      expect(_prop(frame.root, 'padding'), _moves);
      expect(_prop(frame.root, 'margin'), _moves);
      expect(_prop(frame.root, 'gap'), spaceCss(CoreSpace.space12));
    });

    testComponents('dot spacing, default and override', (tester) async {
      ResolvedDotIndicator resolve(
        BuildContext context, {
        CoreDotIndicatorStyle? style,
      }) => resolveDotIndicator(
        context,
        direction: CoreAxis.horizontal,
        size: CoreDotIndicatorSize.md,
        length: 3,
        activeIndex: 0,
        isClickable: false,
        scopeId: 'probe',
        dotIndicatorStyle: style,
      );
      final byDefault = _read(tester, resolve);
      final overridden = _read(
        tester,
        (context) => resolve(
          context,
          style: const CoreDotIndicatorStyle(spacing: CoreSpace.space12),
        ),
      );

      expect(_prop(byDefault.dots.first.root, 'margin-inline-end'), _moves);
      expect(
        _prop(overridden.dots.first.root, 'margin-inline-end'),
        spaceCss(CoreSpace.space12),
      );
    });

    testComponents('accordion item spacing', (tester) async {
      final accordion = _read(
        tester,
        (context) => resolveAccordion(
          context,
          accordionStyle: const CoreAccordionStyle(
            itemSpacing: CoreSpace.space8,
          ),
        ),
      );

      expect(_prop(accordion.root, 'row-gap'), spaceCss(CoreSpace.space8));
    });
  });

  group('the multi-answer card moves only its authored padding', () {
    testComponents('the border compensation rides beside it, pinned', (
      tester,
    ) async {
      // The default widths are equal, so a card only compensates when the
      // caller states a thicker selected border.
      final card = _read(
        tester,
        (context) => resolveMultiAnswerCard(
          context,
          multiAnswerCardStyle: const CoreMultiAnswerCardStyle(
            selectedBorderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      );

      const padding = CoreMultiAnswerCardStyle.defaultPadding;
      const compensation =
          CoreStrokeWidth.stroke2 - CoreMultiAnswerCardStyle.defaultBorderWidth;
      final side =
          'calc(${spaceCss(padding.top)} + ${pinnedLengthCss(compensation)})';
      // Every state carries the same padding, so the content never moves
      // between them.
      for (final state in [card.root, card.hoverRoot, card.selectedRoot]) {
        expect(_prop(state, 'padding'), '$side $side $side $side');
      }
    });

    testComponents('no compensation leaves the bare variable', (tester) async {
      final card = _read(
        tester,
        (context) => resolveMultiAnswerCard(
          context,
          multiAnswerCardStyle: const CoreMultiAnswerCardStyle(
            selectedBorderWidth: CoreStrokeWidth.stroke1,
          ),
        ),
      );

      final side = spaceCss(CoreMultiAnswerCardStyle.defaultPadding.top);
      expect(_prop(card.root, 'padding'), '$side $side $side $side');
    });
  });

  group('stays put — the Flutter twin leaves it out of the density', () {
    testComponents('avatar group overlap is a pinned margin, not a class', (
      tester,
    ) async {
      final group = _read(
        tester,
        (context) => resolveAvatarGroup(
          context,
          direction: CoreAvatarGroupDirection.toLeft,
        ),
      );

      // A `-space-x-*` utility would read the spacing variable.
      expect(group.root.className, isNot(contains('space-x')));
      // The first avatar stays where it is; every later one is pulled back
      // over its predecessor by the overlap.
      expect(group.item.inlineStyles?.properties['margin-left'], isNull);
      expect(
        _prop(group.followingItem, 'margin-left'),
        pinnedLengthCss(-CoreAvatarGroupStyle.defaultOverlap),
      );
      expect(_prop(group.followingItem, 'margin-left'), _stays);
    });

    testComponents('a right-stacked group keeps the same pull', (tester) async {
      final group = _read(
        tester,
        (context) => resolveAvatarGroup(
          context,
          direction: CoreAvatarGroupDirection.toRight,
        ),
      );

      expect(group.root.className, contains('flex-row-reverse'));
      expect(group.root.className, isNot(contains('space-x')));
      expect(_prop(group.followingItem, 'margin-left'), _stays);
    });

    testComponents('extra avatar spacing is spacing and still moves', (
      tester,
    ) async {
      final group = _read(
        tester,
        (context) => resolveAvatarGroup(
          context,
          direction: CoreAvatarGroupDirection.toLeft,
          avatarGroupStyle: const CoreAvatarGroupStyle(
            extraSpacing: CoreSpace.space8,
          ),
        ),
      );

      expect(_prop(group.root, 'column-gap'), spaceCss(CoreSpace.space8));
    });

    testComponents('the avatar badge inset is a position', (tester) async {
      final avatar = _read(
        tester,
        (context) => resolveAvatar(
          context,
          size: CoreComponentSize.md,
          shape: CoreAvatarShape.circle,
          ring: false,
          avatarStyle: const CoreAvatarStyle(badgeInset: CoreSpace.space8),
        ),
      );

      // The anchor is the 45° point of the md disc, pulled 8 toward the
      // centre — a pinned length, not a spacing variable.
      final props = avatar.badgeSlot.inlineStyles!.properties;
      final anchor = CoreAvatarStyle.badgeAnchorFor(
        diameter: CoreAvatarStyle.diameterFor(CoreComponentSize.md),
        inset: CoreSpace.space8,
        alignment: CoreAvatarStyle.defaultBadgeAlignment,
        placement: CoreAvatarBadgePlacement.outline,
      );
      expect(props['left'], pinnedLengthCss(anchor.x));
      expect(props['top'], pinnedLengthCss(anchor.y));
      expect(props['left'], isNot(contains('var(')));
    });

    testComponents('the timeline dot seat and connector gap', (tester) async {
      final timeline = _read(
        tester,
        (context) => resolveTimeline(
          context,
          timelineStyle: const CoreTimelineStyle(
            dotTopMargin: CoreSpace.space8,
            connectorSpacing: CoreSpace.space8,
          ),
        ),
      );

      // The dot's seat against the title is a position, not spacing.
      expect(
        _prop(timeline.dot, 'margin-top'),
        pinnedLengthCss(CoreSpace.space8),
      );
      // The gap under the dot is spacing between two elements: it moves
      // with the density, like the Flutter twin's `theme.geometry.space`.
      expect(
        _prop(timeline.connector, 'margin-top'),
        spaceCss(CoreSpace.space8),
      );
      // The line reaches across the row spacing (moves) and down to the next
      // dot's seat (a position, stays), stopping the gap short of it (moves).
      expect(
        _prop(timeline.connector, 'margin-bottom'),
        'calc(-1 * (${spaceCss(CoreTimelineStyle.defaultRowSpacing)} + '
        '${pinnedLengthCss(CoreSpace.space8)} - '
        '${spaceCss(CoreSpace.space8)}))',
      );
    });

    testComponents('a card overlay inset is a position', (tester) async {
      final card = _read(
        tester,
        (context) => resolveCard(
          context,
          variant: CoreCardVariant.defaultVariant,
          hasMedia: false,
          interactive: false,
          cardStyle: const CoreCardStyle(overlayInset: CoreSpace.space8),
        ),
      );

      expect(
        _prop(card.overlayWrapper, 'inset'),
        pinnedLengthCss(CoreSpace.space8),
      );
    });

    testComponents('the code-snippet actions sit at a pinned offset', (
      tester,
    ) async {
      final snippet = _read(
        tester,
        (context) => resolveCodeSnippet(
          context,
          lineCount: 1,
          codeSnippetStyle: const CoreCodeSnippetStyle(
            copyButtonOffset: CoreSpace.space8,
          ),
        ),
      );

      expect(_prop(snippet.actionWrapper, 'top'), _stays);
      expect(_prop(snippet.actionWrapper, 'right'), _stays);
    });

    testComponents('the scrollbar thumb inset is its own footprint', (
      tester,
    ) async {
      final css = _read(
        tester,
        (context) => resolveScrollbarCss(
          context,
          axis: CoreScrollbarAxis.vertical,
          visibility: CoreScrollbarVisibility.auto,
          scopeId: 'probe',
          scrollbarStyle: const CoreScrollbarStyle(
            thumbInset: CoreSpace.space8,
          ),
        ),
      );

      expect(css, contains(pinnedLengthCss(CoreSpace.space8)));
      expect(css, isNot(contains('var(--coui-space-')));
    });

    testComponents('the input-otp cell box stays put at every size', (
      tester,
    ) async {
      // The Flutter twin scales the cell box without the geometry, so no
      // density reaches it — at `lg` (56, a control-ladder number) no more
      // than at `md` (40, one too). Only the gap between cells moves.
      for (final size in CoreInputOtpSize.values) {
        final otp = _read(
          tester,
          (context) => resolveInputOtp(context, enabled: true, size: size),
        );

        for (final property in ['width', 'height']) {
          final value = _prop(otp.cell, property);
          expect(value, _stays, reason: '$size cell $property');
          expect(
            value,
            isNot(contains('var(--coui-control-height')),
            reason: '$size cell $property',
          );
        }
        expect(_prop(otp.root, 'height'), _stays, reason: '$size row');
        expect(
          otp.root.className,
          contains('gap-space'),
          reason: '$size gap rides the spacing scale',
        );
      }
    });

    testComponents('trend-chart bar spacing draws the bar width', (
      tester,
    ) async {
      final chart = _read(
        tester,
        (context) => resolveTrendChart(
          context,
          variant: CoreTrendChartVariant.bar,
          points: [
            CoreTrendPoint(date: DateTime(2026), value: 1),
            CoreTrendPoint(date: DateTime(2026, 2), value: 2),
          ],
          trendChartStyle: const CoreTrendChartStyle(
            barSpacing: CoreSpace.space8,
          ),
        ),
      );

      for (final bar in chart.bars) {
        expect(
          _prop(bar, 'width'),
          contains(pinnedLengthCss(CoreSpace.space8)),
        );
        expect(_prop(bar, 'width'), isNot(contains('var(--coui-space-')));
      }
    });
  });

  // The overlay engine takes its lengths as numbers in collision math, where
  // no spacing variable can reach — so the spacing among them is moved by
  // the density the document carries when the panel opens, the number the
  // Flutter twin's inset conversion would draw.
  group('the overlay engine gets the density-moved number', () {
    testComponents('a popover keeps its distance from the viewport edge', (
      tester,
    ) async {
      for (final (density, side) in [
        (CoreDensity.compact, 4.0),
        (CoreDensity.standard, 8.0),
        (CoreDensity.spacious, 12.0),
      ]) {
        final config = _read(
          tester,
          (context) => resolvePopoverConfig(context, density: density),
        );
        expect(
          config.viewportPadding,
          CoreEdgeInsets.all(side),
          reason: density.name,
        );
        // The trigger↔panel gap is a position offset and stays.
        expect(config.gap, CorePopoverStyle.defaultPlacementOffset);
      }

      // A stated padding is spacing too — a 48 header reserve moves a rung.
      final stated = _read(
        tester,
        (context) => resolvePopoverConfig(
          context,
          density: CoreDensity.compact,
          popoverStyle: const CorePopoverStyle(
            viewportPadding: CoreEdgeInsets.only(top: CoreSpace.space48),
          ),
        ),
      );
      expect(stated.viewportPadding.top, 44);
    });

    testComponents('a menubar panel clears the bar by its moved padding', (
      tester,
    ) async {
      // The gap is the offset (4, stays) + the bar's bottom padding (spacing)
      // + its border (1, stays).
      for (final (density, gap) in [
        (CoreDensity.compact, 9.0),
        (CoreDensity.standard, 13.0),
        (CoreDensity.spacious, 17.0),
      ]) {
        final config = _read(
          tester,
          (context) => resolveMenubarConfig(
            context,
            border: true,
            density: density,
            menubarStyle: const CoreMenubarStyle(
              barPadding: CoreEdgeInsets.all(CoreSpace.space8),
            ),
          ),
        );
        expect(config.gap, gap, reason: density.name);
      }

      // The default bottom padding (4) sits on the density's floor.
      for (final density in CoreDensity.values) {
        final config = _read(
          tester,
          (context) =>
              resolveMenubarConfig(context, border: true, density: density),
        );
        expect(config.gap, 9, reason: density.name);
      }
    });
  });

  group('the bottom action bar adds the safe area to its bottom padding', () {
    testComponents('the bottom edge is a sum, the rest stay variables', (
      tester,
    ) async {
      final bar = _read(
        tester,
        (context) => resolveBottomActionBar(
          context,
          layout: CoreBottomActionBarLayout.vertical,
          showDivider: true,
        ),
      );

      const padding = CoreBottomActionBarStyle.defaultPadding;
      // The style's bottom padding is a spacing step, so a density moves it;
      // the device's safe area is added to it as an `env()` operand and is
      // not a spacing at all, so nothing here pins it or gives it a fallback.
      expect(
        _prop(bar.root, 'padding-bottom'),
        'calc(${spaceCss(padding.bottom)} + env(safe-area-inset-bottom))',
      );
      expect(_prop(bar.root, 'padding-bottom'), _moves);
      expect(_prop(bar.root, 'padding'), _moves);
      expect(_prop(bar.root, 'gap'), _moves);
      expect(_prop(bar.actions, 'gap'), _moves);
    });
  });
}
