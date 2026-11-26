// The parts a bottom sheet is drawn with — a description under the title,
// the header without its close button or its rule, and the grab handle on
// the edge facing the screen centre — and the drag that the handle invites.
//
// The Web twin's markup for the same parts is in
// `packages/coui_web/test/components/overlay/drawer_sheet_test.dart`.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kContentHeight = 120.0;

/// Wraps every route (including the drawer route pushed on the root
/// `Navigator`) with the CoUI `Theme`, so the panel resolves `Theme.of`.
material.Widget _buildThemedApp(material.Widget home) => material.MaterialApp(
  builder: (context, built) => Theme(data: const ThemeData(), child: built!),
  home: home,
);

/// A screen with a button that opens [drawer] from its own side. The route
/// owns the drag on this platform, so the drag settings go to `openDrawer`.
material.Widget _host(Drawer drawer) => _buildThemedApp(
  material.Builder(
    builder: (context) => material.Center(
      child: material.ElevatedButton(
        onPressed: () => openDrawer<void>(
          context: context,
          side: drawer.side,
          draggable: drawer.draggable,
          dragDismissThreshold: drawer.dragDismissThreshold,
          builder: (context) => drawer,
        ),
        child: const material.Text('open'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Drawer drawer) async {
  await tester.pumpWidget(_host(drawer));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const _kContent = material.SizedBox(height: _kContentHeight, width: 200);

Finder _handle() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_DrawerHandle',
);

/// The pill itself — the one decorated box inside the handle.
Finder _pill() => find.descendant(
  of: _handle(),
  matching: find.byWidgetPredicate(
    (widget) => widget is material.Container && widget.decoration != null,
  ),
);

Finder _closeButton() =>
    find.descendant(of: find.byType(Drawer), matching: find.byType(Button));

Rect _panel(WidgetTester tester) => tester.getRect(find.byType(Drawer));

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Drawer)));

void main() {
  group('Drawer description', () {
    testWidgets('sits under the title in the supporting-text style', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Choose a currency',
          description: 'The currency you will receive',
          content: _kContent,
        ),
      );

      final title = tester.getRect(find.text('Choose a currency'));
      final description = tester.getRect(
        find.text('The currency you will receive'),
      );
      expect(description.top, greaterThan(title.bottom));
      expect(
        description.top - title.bottom,
        CoreDrawerStyle.defaultTitleDescriptionGapStyle.size,
        reason: 'the title-to-description gap is the Core default',
      );

      final theme = _theme(tester);
      final style = material.DefaultTextStyle.of(
        tester.element(find.text('The currency you will receive')),
      ).style;
      expect(
        style.color,
        theme.colorScheme
            .resolve(CoreDrawerStyle.defaultDescriptionStyle.color!)
            .toValue(),
      );
      expect(
        style.fontSize,
        CoreDrawerStyle.defaultDescriptionStyle.toValue(theme: theme).fontSize,
      );
    });

    testWidgets('a description alone still draws the header', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          description: 'Only a description',
          content: _kContent,
        ),
      );

      expect(find.text('Only a description'), findsOneWidget);
      expect(_closeButton(), findsOneWidget);
    });

    testWidgets('no title and no description → no header at all', (
      tester,
    ) async {
      await _open(tester, const Drawer(side: .bottom, content: _kContent));

      expect(_closeButton(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
    });
  });

  group('Drawer showCloseButton', () {
    testWidgets('is on by default — a titled header keeps its close button', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .bottom, title: 'Title', content: _kContent),
      );

      expect(_closeButton(), findsOneWidget);
    });

    testWidgets('off — the header draws the title without the button', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          showCloseButton: false,
          content: _kContent,
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(_closeButton(), findsNothing);
    });
  });

  group('Drawer header rule', () {
    testWidgets('a zero-thickness divider style takes no space', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          content: _kContent,
          drawerStyle: CoreDrawerStyle(
            dividerStyle: CoreDividerStyle(thickness: 0),
          ),
        ),
      );

      final rule = find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Divider),
      );
      expect(tester.getSize(rule).height, 0);
    });
  });

  group('Drawer showDragHandle', () {
    testWidgets('is off by default — no handle is drawn', (tester) async {
      await _open(tester, const Drawer(side: .bottom, content: _kContent));

      expect(_handle(), findsNothing);
    });

    testWidgets('bottom — a centred pill above the header', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          showDragHandle: true,
          content: _kContent,
        ),
      );

      final panel = _panel(tester);
      final pill = tester.getRect(_pill());
      expect(pill.size, const Size(48, 6));
      expect(pill.top - panel.top, CoreDrawerStyle.defaultDragHandleInset);
      expect(pill.center.dx, closeTo(panel.center.dx, 0.01));
      expect(
        tester.getRect(find.text('Title')).top,
        greaterThan(pill.bottom),
        reason: 'the handle leads the header on a bottom sheet',
      );
    });

    testWidgets('top — a centred pill below the content', (tester) async {
      await _open(
        tester,
        const Drawer(side: .top, showDragHandle: true, content: _kContent),
      );

      final panel = _panel(tester);
      final pill = tester.getRect(_pill());
      expect(
        panel.bottom - pill.bottom,
        CoreDrawerStyle.defaultDragHandleInset,
      );
      expect(pill.center.dx, closeTo(panel.center.dx, 0.01));
    });

    testWidgets('left — an upright pill on the inner (right) edge', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(showDragHandle: true, content: _kContent),
      );

      final panel = _panel(tester);
      final pill = tester.getRect(_pill());
      expect(pill.size, const Size(6, 48));
      expect(panel.right - pill.right, CoreDrawerStyle.defaultDragHandleInset);
      expect(pill.center.dy, closeTo(panel.center.dy, 0.01));
    });

    testWidgets('right — an upright pill on the inner (left) edge', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .right, showDragHandle: true, content: _kContent),
      );

      final panel = _panel(tester);
      final pill = tester.getRect(_pill());
      expect(pill.left - panel.left, CoreDrawerStyle.defaultDragHandleInset);
    });

    testWidgets('paints the handle chrome the drawer style states', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          showDragHandle: true,
          content: _kContent,
          drawerStyle: CoreDrawerStyle(
            dragHandleWidth: 40,
            dragHandleThickness: 4,
            dragHandleColor: CoreColor.token(CoreColors.outlineVariant),
          ),
        ),
      );

      expect(tester.getSize(_pill()), const Size(40, 4));
      final decoration =
          tester.widget<material.Container>(_pill()).decoration!
              as material.BoxDecoration;
      expect(
        decoration.color,
        _theme(tester).colorScheme
            .resolve(const CoreColor.token(CoreColors.outlineVariant))
            .toValue(),
      );
    });

    testWidgets('the default pill is the surface-container step', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .bottom, showDragHandle: true, content: _kContent),
      );

      final decoration =
          tester.widget<material.Container>(_pill()).decoration!
              as material.BoxDecoration;
      expect(
        decoration.color,
        _theme(
          tester,
        ).colorScheme.resolve(CoreDrawerStyle.defaultDragHandleColor).toValue(),
      );
    });

    testWidgets('is decorative — it adds nothing for assistive technology', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .bottom, showDragHandle: true, content: _kContent),
      );

      expect(
        find.ancestor(of: _pill(), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });
  });

  group('Drawer docks to the edge the route opened it from', () {
    testWidgets('a panel that states no side follows openDrawer(side:)', (
      tester,
    ) async {
      // The docs' pattern: the side goes to `openDrawer`, the panel is a plain
      // `Drawer(...)`. The Web twin reads the side off its entry the same way.
      await tester.pumpWidget(
        _buildThemedApp(
          material.Builder(
            builder: (context) => material.Center(
              child: material.ElevatedButton(
                onPressed: () => openDrawer<void>(
                  context: context,
                  side: .bottom,
                  builder: (context) =>
                      const Drawer(showDragHandle: true, content: _kContent),
                ),
                child: const material.Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final panel = _panel(tester);
      final pill = tester.getRect(_pill());
      expect(
        pill.size,
        const Size(48, 6),
        reason: 'a bottom sheet lays it flat',
      );
      expect(pill.top - panel.top, CoreDrawerStyle.defaultDragHandleInset);
      final decoration =
          tester
                  .widget<material.DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(Drawer),
                          matching: find.byType(material.DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as material.BoxDecoration;
      final radius = decoration.borderRadius! as material.BorderRadius;
      expect(radius.bottomLeft, material.Radius.zero);
      expect(radius.bottomRight, material.Radius.zero);
      expect(radius.topLeft, isNot(material.Radius.zero));
    });
  });

  group('Drawer drag on the handle', () {
    testWidgets('past half the sheet dismisses — measured on the sheet, '
        'not the screen', (tester) async {
      await _open(
        tester,
        const Drawer(side: .bottom, showDragHandle: true, content: _kContent),
      );

      final panelHeight = _panel(tester).height;
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      // Past half the sheet but short of half the screen: only a fraction
      // of the sheet's own height can dismiss it.
      final drag = panelHeight * 0.5 + kDragSlopDefault + 8;
      expect(drag, lessThan(screenHeight * 0.5));

      await tester.drag(_handle(), Offset(0, drag));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('short of half the sheet snaps back', (tester) async {
      await _open(
        tester,
        const Drawer(side: .bottom, showDragHandle: true, content: _kContent),
      );

      final docked = _panel(tester);
      await tester.drag(_handle(), Offset(0, docked.height * 0.25));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(_panel(tester), docked);
    });

    testWidgets('a panel that is not draggable stays put', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          showDragHandle: true,
          draggable: false,
          content: _kContent,
        ),
      );

      await tester.drag(_handle(), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });
  });

  group('Swiper draws its handle through the drawer', () {
    /// Pumps a bottom [Swiper] and opens it the way a page does — by
    /// flipping its controlled `open` from a button.
    Future<void> openSwiper(
      WidgetTester tester, {
      required bool showDragHandle,
      CoreSwiperStyle? style,
    }) async {
      var open = false;
      await tester.pumpWidget(
        _buildThemedApp(
          material.StatefulBuilder(
            builder: (context, setState) => material.Column(
              children: [
                material.ElevatedButton(
                  onPressed: () => setState(() => open = true),
                  child: const material.Text('open swiper'),
                ),
                Swiper(
                  open: open,
                  position: .bottom,
                  showDragHandle: showDragHandle,
                  swiperStyle: style,
                  overlayContent: const material.Text('overlay'),
                  child: const material.SizedBox(width: 400, height: 200),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('open swiper'));
      await tester.pumpAndSettle();
      expect(find.text('overlay'), findsOneWidget);
    }

    testWidgets("exactly one handle — the drawer's", (tester) async {
      await openSwiper(tester, showDragHandle: true);

      expect(_handle(), findsOneWidget);
      expect(tester.getSize(_pill()), const Size(48, 6));
    });

    testWidgets('no handle when the swiper turns it off', (tester) async {
      await openSwiper(tester, showDragHandle: false);

      expect(_handle(), findsNothing);
    });

    testWidgets('the deprecated flat handle fields are still honoured', (
      tester,
    ) async {
      await openSwiper(
        tester,
        showDragHandle: true,
        // The old spelling stays readable until it is removed.
        // ignore: deprecated_member_use
        style: const CoreSwiperStyle(dragHandleWidth: 40),
      );

      expect(tester.getSize(_pill()).width, 40);
    });

    testWidgets('the drawer style wins over the deprecated spelling', (
      tester,
    ) async {
      await openSwiper(
        tester,
        showDragHandle: true,
        style: const CoreSwiperStyle(
          // The old spelling stays readable until it is removed.
          // ignore: deprecated_member_use
          dragHandleWidth: 40,
          drawerStyle: CoreDrawerStyle(dragHandleWidth: 56),
        ),
      );

      expect(tester.getSize(_pill()).width, 56);
    });
  });
}
