/// Pins the width overflow the Chip docs preview's `cast-motion` variant
/// used to paint — the same shape and the same fix as
/// `button_cast_motion_preview_overflow_test.dart`, mirrored here because
/// Chip is a separate `kDocsWideComponents` registration (the set keys on
/// the component, not on a shared "row of three" category).
///
/// The three-chip row (`기본` / `그림자 없음` / `반대로`) is
/// `mainAxisSize: .min` with no shrink, wrap or scroll affordance. The
/// `.preview-container` / `.preview-pane` / `.preview-content` CSS grid is
/// the same markup regardless of which component fills it, so the
/// side-by-side pane's usable content width sweeps the same
/// ~105–235px band (1024–1920px viewports) that
/// `button_cast_motion_preview_overflow_test.dart` measured directly —
/// well under the row's ~159px intrinsic width. Fixed by putting `chip`
/// in `kDocsWideComponents` (stacked panes → full cell width).
///
/// Shares Menubar/Button's traps, both handled below:
///
/// 1. `DebugOverflowIndicatorMixin` reports a given `RenderFlex` only
///    **once per render-object lifetime**. Sweeping sizes over one
///    element tree silently suppresses every step after the first, so
///    each case unmounts first.
/// 2. A `SizedBox` around the example would put the row's constraint at
///    the full 800px test surface instead of the embed's real width —
///    the harness sizes the **view**, mirroring what the embed actually
///    constrains.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_cast_motion_example.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The narrowest side-by-side gallery pane the cast-motion row was ever
/// handed — see the library doc for why this reuses Button's measured
/// value rather than re-sweeping the identical CSS grid.
const double _kNarrowestSideBySidePane = 105.0;

/// A full-width stacked pane — what `kDocsWideComponents` buys. The live
/// site measured ~638px at a 1400px viewport; 600 stays comfortably
/// under that so the assertion does not ride the exact pixel.
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

  await tester.pumpWidget(_previewApp(const ChipCastMotionExample()));
  final settled = await tester.pumpAndSettle();
  expect(settled, greaterThanOrEqualTo(0));

  material.FlutterError.onError = previousOnError;

  return caught;
}

void main() {
  group('Chip docs preview registration', () {
    test('is stacked, so cast-motion gets the full cell width', () {
      // Without this the gallery splits the row into columns and each
      // column again into two panes, leaving the embed far under the
      // three-chip row's intrinsic width.
      expect(kDocsWideComponents, contains('chip'));
    });
  });

  group('Chip cast-motion preview geometry', () {
    testWidgets('the three-chip row renders without overflow at a stacked pane width', (
      tester,
    ) async {
      final overflows = await _overflowsAt(
        tester,
        const material.Size(_kStackedPaneWidth, 200),
      );

      expect(overflows, isEmpty, reason: 'cast-motion row overflowed at the stacked pane width');
    });

    testWidgets('the old side-by-side pane width is what used to overflow', (
      tester,
    ) async {
      // Negative control. If this ever stops overflowing, the geometry
      // moved and the assertion above is no longer pinning anything — it
      // would pass on a component that cannot fail.
      final overflows = await _overflowsAt(
        tester,
        const material.Size(_kNarrowestSideBySidePane, 200),
      );

      expect(
        overflows,
        isNotEmpty,
        reason:
            'the narrow side-by-side pane should still overflow — that is '
            'why chip is in kDocsWideComponents',
      );
    });
  });
}
