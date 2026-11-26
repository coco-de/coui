/// Pins the two overflows the Menubar docs preview used to paint.
///
/// Both were steady-state, not transient, and they failed for different
/// reasons — so they need different halves of the fix and are asserted
/// separately here:
///
/// * **Width** — the trigger `Row` is `mainAxisSize: .min` with no
///   shrink, wrap or scroll affordance, so a pane narrower than the bar
///   overflows on the right. Fixed by putting `menubar` in
///   `kDocsWideComponents` (stacked panes → full cell width).
/// * **Height** — the dropdown needs ~129px, and nothing sizes the
///   preview from its content — the height is the tier, chosen before the
///   view exists. Both panes render on `maxHeight`, so the old 100px
///   floor was latent rather than visible — but the band is a promise
///   that any height in it renders, so the floor was raised in
///   `preview_constraints.dart`. Stacking does not help this one; it
///   changes columns, not height.
///
/// Two traps make this kind of test pass vacuously; both are handled
/// below and neither is obvious from a green run:
///
/// 1. `DebugOverflowIndicatorMixin` reports a given `RenderFlex` only
///    **once per render-object lifetime**. Sweeping sizes over one
///    element tree silently suppresses every step after the first, so
///    each case unmounts first.
/// 2. Widget tests default to `FocusHighlightStrategy.touch`, which
///    suppresses `FocusableActionDetector.onShowHoverHighlight` and so
///    stops `Clickable.onHover` from ever firing — any hover assertion
///    would then pass while exercising nothing.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/menubar/menubar_default_example.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The narrowest Flutter pane the side-by-side gallery ever produced,
/// measured across viewports (1440px gave the worst case).
const double _kNarrowestSideBySidePane = 138.5;

/// A full-width stacked pane — what `kDocsWideComponents` buys.
const double _kStackedPaneWidth = 600;

/// Mirrors `preview_app.dart`: the embed centres its content at the top
/// with a little breathing room.
material.Widget _previewApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    ),
  ),
);

/// Sizes the **view** — not a `SizedBox` — to [size], because that is
/// what the embed actually constrains.
///
/// A `SizedBox` around the example would be a third silent trap: the
/// dropdown is mounted in the app-level `Overlay`, so it escapes any box
/// inside the tree and would be laid out against the full 800px test
/// surface. Every height assertion would then pass no matter what the
/// declared floor was — verified by injecting a 100px floor and watching
/// this suite stay green until the harness was moved onto the view.
void _sizeView(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Renders the real docs example at [size] on a **fresh** tree and
/// returns every overflow FlutterError raised, after optionally opening
/// [openMenu].
///
/// Unmounts first — see trap (1) in the library doc.
Future<List<String>> _overflowsAt(
  WidgetTester tester,
  Size size, {
  String? openMenu,
}) async {
  await tester.pumpWidget(const material.SizedBox.shrink());
  await tester.pump();
  _sizeView(tester, size);

  final caught = <String>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exception.toString();
    if (text.contains('overflowed')) {
      caught.add(text);
    } else {
      previousOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  await tester.pumpWidget(_previewApp(const MenubarDefaultExample()));
  final settled = await tester.pumpAndSettle();
  expect(settled, greaterThanOrEqualTo(0));

  if (openMenu != null) {
    await tester.tap(find.text(openMenu));
    final opened = await tester.pumpAndSettle();
    expect(opened, greaterThanOrEqualTo(0));
  }

  FlutterError.onError = previousOnError;

  return caught;
}

void main() {
  group('Menubar docs preview registration', () {
    test('is stacked, so each platform gets the full cell width', () {
      // The width half of the fix. Without this the gallery splits the
      // row into columns and each column into two panes, leaving the
      // embed far under the bar's intrinsic width.
      expect(kDocsWideComponents, contains('menubar'));
    });

    test('declares a height band at all', () {
      expect(kDocsPreviewConstraints['menubar'], isNotNull);
    });
  });

  group('Menubar preview geometry', () {
    testWidgets('the bar renders without overflow across the height band', (
      tester,
    ) async {
      // Both ends, because which end the embed actually resolves to is a
      // CSS detail we do not control from here — today it lands on
      // maxHeight. The band is a promise that any height in it renders.
      final constraints = kDocsPreviewConstraints['menubar']!;

      for (final height in [constraints.minHeight, constraints.maxHeight]) {
        final overflows = await _overflowsAt(
          tester,
          Size(_kStackedPaneWidth, height),
        );

        expect(overflows, isEmpty, reason: 'bar overflowed at height $height');
      }
    });

    testWidgets('every menu opens without overflow across the height band', (
      tester,
    ) async {
      // All three menus, not just the tallest: at a 100px floor the
      // three-entry Edit menu overflows too, which a spot check of one
      // menu would have missed.
      final constraints = kDocsPreviewConstraints['menubar']!;

      for (final height in [constraints.minHeight, constraints.maxHeight]) {
        for (final menu in ['파일', '편집', '보기']) {
          final overflows = await _overflowsAt(
            tester,
            Size(_kStackedPaneWidth, height),
            openMenu: menu,
          );

          expect(
            overflows,
            isEmpty,
            reason: '$menu overflowed at height $height',
          );
        }
      }
    });

    testWidgets('hover-switching between menus adds no overflow', (
      tester,
    ) async {
      // Guards the #4165 hover path against regressing into the layout
      // it shares with the click path.
      material.FocusManager.instance.highlightStrategy = material.FocusHighlightStrategy.alwaysTraditional; // trap (2)
      addTearDown(
        () => material.FocusManager.instance.highlightStrategy = material.FocusHighlightStrategy.automatic,
      );
      // At the height the embed resolves to (maxHeight, see above). At
      // minHeight the open File panel cannot fit under the bar, so it is
      // shifted up over the bar and covers the neighbouring triggers —
      // the pointer then lands on the panel and no switch can happen,
      // which would make this test about the floor, not the hover path.
      final constraints = kDocsPreviewConstraints['menubar']!;
      _sizeView(
        tester,
        Size(_kStackedPaneWidth, constraints.maxHeight),
      );

      final caught = <String>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exception.toString();
        if (text.contains('overflowed')) {
          caught.add(text);
        } else {
          previousOnError?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(_previewApp(const MenubarDefaultExample()));
      final settled = await tester.pumpAndSettle();
      expect(settled, greaterThanOrEqualTo(0));

      await tester.tap(find.text('파일'));
      final opened = await tester.pumpAndSettle();
      expect(opened, greaterThanOrEqualTo(0));

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      for (final menu in ['편집', '보기', '편집']) {
        await gesture.moveTo(tester.getCenter(find.text(menu)));
        final switched = await tester.pumpAndSettle();
        expect(switched, greaterThanOrEqualTo(0));
      }

      FlutterError.onError = previousOnError;

      // The switch really happened — otherwise "no overflow" is vacuous.
      expect(find.text('잘라내기'), findsOneWidget);
      expect(caught, isEmpty);
    });

    testWidgets('the old side-by-side pane width is what used to overflow', (
      tester,
    ) async {
      // Negative control. If this ever stops overflowing, the geometry
      // moved and the two assertions above are no longer pinning
      // anything — they would pass on a component that cannot fail.
      final overflows = await _overflowsAt(
        tester,
        const Size(_kNarrowestSideBySidePane, 400),
      );

      expect(
        overflows,
        isNotEmpty,
        reason:
            'the narrow side-by-side pane should still overflow — that is '
            'why menubar is in kDocsWideComponents',
      );
    });
  });
}
