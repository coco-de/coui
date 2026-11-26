/// Pins the geometry of the Chip docs preview's `variant` example — the
/// three captioned rows (outlined / filled / outlined on a grey `Card`).
///
/// Two things have to stay true together, and neither is visible from a
/// green analyzer:
///
/// 1. The example renders without a `RenderFlex` overflow at a stacked
///    pane width (`chip` is in `kDocsWideComponents`, so both platforms
///    get the full cell).
/// 2. Its height fits the `chip/variant` constraint the registry gives it.
///    A constraint tighter than the content clips the grey-surface row,
///    which is the row the example exists to show.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_variant_example.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// A full-width stacked pane — what `kDocsWideComponents` buys. The live
/// site measured ~638px at a 1400px viewport; 600 stays under that.
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

void main() {
  group('Chip variant preview constraint', () {
    test('is registered, and tall enough for the three rows', () {
      final constraints = kDocsPreviewConstraints['chip/variant'];

      expect(constraints, isNotNull, reason: 'chip/variant has no entry');
      expect(constraints!.maxHeight, kDocsTallConstraints.maxHeight);
    });
  });

  group('Chip variant preview geometry', () {
    testWidgets('renders without overflow and fits its constraint', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const material.Size(_kStackedPaneWidth, 600);
      addTearDown(tester.view.reset);

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

      await tester.pumpWidget(_previewApp(const ChipVariantExample()));
      await tester.pumpAndSettle();
      material.FlutterError.onError = previousOnError;

      expect(caught, isEmpty, reason: 'variant preview overflowed');

      final height = tester.getSize(find.byType(ChipVariantExample)).height;
      expect(height, lessThanOrEqualTo(kDocsTallConstraints.maxHeight));
      // Not a measurement of the cap — a guard that the entry is still
      // buying something. At or under the medium tier's cap, Flutter would
      // fit the smaller tier, but the Web twin has no slack against it, so
      // this only fails once the content is clearly short of that cap.
      expect(
        height,
        greaterThan(kDocsDefaultConstraints.maxHeight),
        reason: 'the content fits the default tier — drop chip/variant',
      );
    });
  });
}
