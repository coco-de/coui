// Basic, Listing, Card and AppBar defaults as the Web resolvers emit them.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/basic/basic_style.dart';
import 'package:coui_web/src/components/layout/listing/listing_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every `<div>` whose class list holds all of [classes] (whole-class match).
Finder _divWithClasses(List<String> classes) => find.byComponentPredicate((c) {
  if (c is! div) return false;
  final present = c.classes?.split(' ').toSet() ?? const <String>{};
  return classes.every(present.contains);
});

void main() {
  group('Basic row layout', () {
    testComponents('leading and trailing are centered on the row', (
      tester,
    ) async {
      late ResolvedBasic resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveBasic(context, forceTextStyle: true);
            return const div([]);
          },
        ),
      );
      await tester.pump();

      expect(
        resolved.leadingSlot.inlineStyles?.properties['align-items'],
        'center',
      );
      expect(
        resolved.trailingSlot.inlineStyles?.properties['align-items'],
        'center',
      );
    });

    testComponents('the gap between leading, body and trailing is 12', (
      tester,
    ) async {
      late ResolvedBasic resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveBasic(context, forceTextStyle: true);
            return const div([]);
          },
        ),
      );
      await tester.pump();

      expect(resolved.titleContentGapStyle.size, CoreSpace.space12);
    });
  });

  group('Basic subtitle ink', () {
    testComponents('the subtitle is onSurfaceSubtle, title stays onSurface', (
      tester,
    ) async {
      late ResolvedBasic resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveBasic(context, forceTextStyle: true);
            return const div([]);
          },
        ),
      );
      await tester.pump();

      final subtitle = resolved.subtitleSlot.className;
      final title = resolved.titleSlot.className;
      expect(subtitle.split(' '), contains('text-on-surface-subtle'));
      expect(subtitle.split(' '), isNot(contains('text-on-surface-variant')));
      expect(title.split(' '), contains('text-on-surface'));
    });
  });

  group('Listing row padding', () {
    testComponents('a row pads 12 above and below and 0 at the sides', (
      tester,
    ) async {
      late ResolvedListingRow resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveListingRow(context);
            return const div([]);
          },
        ),
      );
      await tester.pump();

      expect(
        resolved.root.inlineStyles?.properties['padding'],
        'var(--coui-space-12) var(--coui-space-0) '
        'var(--coui-space-12) var(--coui-space-0)',
      );
    });
  });

  group('Listing row rule', () {
    Component rows({bool? itemBorder}) => Listing(
      itemBorder: itemBorder,
      children: const [
        ListRow(children: [ListCol(child: Text('A'))]),
        ListRow(children: [ListCol(child: Text('B'))]),
        ListRow(children: [ListCol(child: Text('C'))]),
      ],
    );

    testComponents('a Divider sits between rows when nothing is stated', (
      tester,
    ) async {
      pumpWithTheme(tester, rows());
      await tester.pump();

      // Three rows, two gaps — none above the first or below the last.
      expect(find.byType(Divider), findsNComponents(2));
    });

    testComponents('itemBorder: false draws no rule', (tester) async {
      pumpWithTheme(tester, rows(itemBorder: false));
      await tester.pump();

      expect(find.byType(Divider), findsNothing);
    });

    testComponents('the rule carries no colour of its own', (tester) async {
      late ResolvedListing resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveListing(context);
            return const div([]);
          },
        ),
      );
      await tester.pump();

      // Divider owns the line colour (outlineVariant) and thickness; the
      // listing forwards an empty partial so nothing overrides them.
      expect(resolved.dividerStyle, isNotNull);
      expect(resolved.dividerStyle!.color, isNull);
      expect(resolved.dividerStyle!.thickness, isNull);
    });
  });

  group('Card spacing', () {
    testComponents('the default padding is 20 vertical and 24 horizontal', (
      tester,
    ) async {
      late ResolvedCard resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveCard(
              context,
              variant: CoreCardVariant.defaultVariant,
              hasMedia: false,
              interactive: false,
            );
            return const div([]);
          },
        ),
      );
      await tester.pump();

      expect(
        resolved.contentWrapper.inlineStyles?.properties['padding'],
        'var(--coui-space-20) var(--coui-space-24) '
        'var(--coui-space-20) var(--coui-space-24)',
      );
    });

    testComponents('header to body is 8 and body to footer is 12', (
      tester,
    ) async {
      late ResolvedCard resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveCard(
              context,
              variant: CoreCardVariant.defaultVariant,
              hasMedia: false,
              interactive: false,
            );
            return const div([]);
          },
        ),
      );
      await tester.pump();

      expect(resolved.headerBodyGapStyle.size, CoreSpace.space8);
      expect(resolved.bodyFooterGapStyle.size, CoreSpace.space12);
    });
  });

  group('HoverCard panel padding', () {
    testComponents('the panel is a Popup bubble holding the content preset', (
      tester,
    ) async {
      late ResolvedHoverCard resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveHoverCard(context: context);
            return const div([]);
          },
        ),
      );
      await tester.pump();

      // The panel's line lies over its inset: the inset less the border.
      expect(
        resolved.bubble.inlineStyles?.properties['padding'],
        CorePopupStyle.defaultContentPadding.toDeclarationsWithinBorder(
          'padding',
          surfaceClipKeptBorder(
            strokeWidthCss(CorePopupStyle.defaultBorderWidth),
          ),
        )['padding'],
      );
      expect(
        CorePopupStyle.defaultContentPadding,
        const CoreEdgeInsets.all(16),
      );
    });

    testComponents('a caller padding on the panel slot still wins', (
      tester,
    ) async {
      late ResolvedHoverCard resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveHoverCard(
              context: context,
              hoverCardStyle: const CoreHoverCardStyle(
                panelStyle: CorePopupStyle(
                  padding: CoreEdgeInsets.all(CoreSpace.space8),
                ),
              ),
            );
            return const div([]);
          },
        ),
      );
      await tester.pump();

      expect(
        resolved.bubble.inlineStyles?.properties['padding'],
        const CoreEdgeInsets.all(CoreSpace.space8).toDeclarationsWithinBorder(
          'padding',
          surfaceClipKeptBorder(
            strokeWidthCss(CorePopupStyle.defaultBorderWidth),
          ),
        )['padding'],
      );
    });
  });

  group('AppBar bar padding', () {
    testComponents('compact pads its bar 16, standard pads it 8', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.compact),
      );
      await tester.pump();

      expect(
        _divWithClasses(['h-size56', 'pl-space16', 'pr-space16']),
        findsOneComponent,
      );

      pumpWithTheme(tester, const AppBar(title: Text('Title')));
      await tester.pump();

      expect(
        _divWithClasses(['h-size64', 'pl-space8', 'pr-space8']),
        findsOneComponent,
      );
    });

    testComponents('medium keeps 8 on its top row', (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.medium),
      );
      await tester.pump();

      expect(
        _divWithClasses(['h-size48', 'pl-space8', 'pr-space8']),
        findsOneComponent,
      );
    });
  });
}
