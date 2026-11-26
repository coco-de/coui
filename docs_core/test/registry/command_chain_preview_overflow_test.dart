/// Pins the height overflow the Command docs preview's `chain` variant
/// used to paint.
///
/// Unlike a normal chain example (one `.getter` combo instance + one
/// `withStyle` instance stacked with `Gap.space12`), Command's chain
/// example stacks **two full `Command` panels** (search field + two
/// groups + footer each). A single panel already clears
/// `kDocsMediumConstraints` on its own, so the generic chain-lower-bound
/// rule in `docsPreviewConstraintsFor` (which only raises the floor to
/// `kDocsMediumConstraints` when the component's own band is smaller)
/// never engages — `command/chain` inherited plain `kDocsTallConstraints`
/// (100–400px) from the `command` entry.
///
/// Measured against the live docs site (headless Chrome): the Web pane's
/// content `scrollHeight` was ~675px against a 400px `max-height` clip,
/// and the Flutter pane painted `A RenderFlex overflowed by 262 pixels on
/// the bottom.` — matching (400 + 262 = 662px of real content). Fixed by
/// registering a `command/chain` band in `preview_constraints.dart` tall
/// enough to clear the two-panel content.
///
/// Content here is static — typing in the search field does not reflow
/// the item count — so, unlike Menubar's collapsed/open split, min and
/// max do not need to span a wide behavioral range; both just need to
/// clear the measured two-panel height.
///
/// Shares Menubar's traps, both handled below (see
/// `menubar_preview_overflow_test.dart` for the long version):
///
/// 1. `DebugOverflowIndicatorMixin` reports a given `RenderFlex` only
///    **once per render-object lifetime** — each case unmounts first.
/// 2. A `SizedBox` around the example would size the tree against the
///    full 800px test surface instead of the embed's real height — the
///    harness sizes the **view**, mirroring what the embed constrains.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/command/command_chain_example.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// A full-width stacked pane — `command` is already in
/// `kDocsWideComponents`, so this is a comfortable stand-in for that
/// width. The overflow this test pins is a height issue, not a width
/// one.
const double _kStackedPaneWidth = 600;

/// Mirrors `preview_app.dart`: the embed centres its content at the top
/// with a little breathing room.
material.Widget _previewApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: material.Align(
        alignment: material.Alignment.topCenter,
        child: material.Padding(
          padding: const material.EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: child,
        ),
      ),
    ),
  ),
);

/// Sizes the **view** — not a `SizedBox` — to [size], because that is
/// what the embed actually constrains.
void _sizeView(WidgetTester tester, material.Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Renders the real docs example at [size] on a **fresh** tree and
/// returns every overflow FlutterError raised.
///
/// Unmounts first — see trap (1) in the library doc.
Future<List<String>> _overflowsAt(
  WidgetTester tester,
  material.Size size,
) async {
  await tester.pumpWidget(const material.SizedBox.shrink());
  await tester.pump();
  _sizeView(tester, size);

  final caught = <String>[];
  final previousOnError = material.FlutterError.onError;
  material.FlutterError.onError = (details) {
    final text = details.exception.toString();
    if (text.contains('overflowed')) {
      caught.add(text);
    } else {
      previousOnError?.call(details);
    }
  };
  addTearDown(() => material.FlutterError.onError = previousOnError);

  await tester.pumpWidget(_previewApp(const CommandChainExample()));
  final settled = await tester.pumpAndSettle();
  expect(settled, greaterThanOrEqualTo(0));

  material.FlutterError.onError = previousOnError;

  return caught;
}

void main() {
  group('Command chain docs preview registration', () {
    test('declares a height band at the chain variant key', () {
      expect(kDocsPreviewConstraints['command/chain'], isNotNull);
    });

    test('the chain band clears the component-level band', () {
      // command/chain must be its own key, not inherit plain
      // kDocsTallConstraints from 'command' — that 400px cap is exactly
      // what overflowed.
      final chain = kDocsPreviewConstraints['command/chain']!;
      final component = kDocsPreviewConstraints['command']!;
      expect(chain.maxHeight, greaterThan(component.maxHeight));
    });
  });

  group('Command chain preview geometry', () {
    testWidgets('the two-panel chain example renders without overflow across the height band', (
      tester,
    ) async {
      // Both ends, because which end the embed actually resolves to is a
      // CSS detail this test does not control — the band is a promise
      // that any height in it renders.
      final constraints = kDocsPreviewConstraints['command/chain']!;

      for (final height in [constraints.minHeight, constraints.maxHeight]) {
        final overflows = await _overflowsAt(
          tester,
          material.Size(_kStackedPaneWidth, height),
        );

        expect(overflows, isEmpty, reason: 'chain overflowed at height $height');
      }
    });

    testWidgets('the old command-level band is what used to overflow', (
      tester,
    ) async {
      // Negative control. If this ever stops overflowing, the geometry
      // moved and the assertion above is no longer pinning anything — it
      // would pass on a component that cannot fail.
      final oldMaxHeight = kDocsPreviewConstraints['command']!.maxHeight;

      final overflows = await _overflowsAt(
        tester,
        material.Size(_kStackedPaneWidth, oldMaxHeight),
      );

      expect(
        overflows,
        isNotEmpty,
        reason:
            'the old command-level 400px band should still overflow — '
            'that is why command/chain has its own, taller band',
      );
    });
  });
}
