/// The Text gallery's `colors-status` preview sits in the horizontal middle
/// of its stage, as Web draws it and as its `colors-brand` sibling does.
///
/// **Why the middle.** The docs stylesheet centres a Web example whose root
/// has no width of its own (`.preview-content` is a flex column with
/// `align-items: center`), and the Flutter embed mirrors that with
/// `Align(topCenter)` around the example (`docs_site`'s `PreviewApp`). An
/// example that shrinks to its content lands in the middle on both; one that
/// fills the stage starts at the left edge.
///
/// **What went wrong.** The status example lays each role's two swatches in
/// a `Row`. A `Row` is `MainAxisSize.max` unless told otherwise, so inside a
/// `Column` it takes the stage's whole width and the column — which is as
/// wide as its widest child — followed it. Web's equivalent is a block flex
/// row inside a shrink-wrapped column, so it stayed as wide as the title.
/// The two panes then disagreed about where the block starts: Web in the
/// middle, Flutter at the left. `colors-brand` holds only `Text`, which
/// shrinks, so it never showed the difference.
///
/// **What is measured.** The example's rendered box inside the same embed
/// the docs page uses — `Align(topCenter)`, the 16px inset — at the two pane
/// widths the stacked Text gallery gets at 1024px and 1440px viewports (the
/// numbers `docs_preview_overflow_test.dart` derives from the deployed
/// page). Real faces are loaded for the same reason that test loads them:
/// flutter_test's own font makes every glyph a 1em square, which turns the
/// 49-character title into a line wider than the pane, and a block that
/// already fills the stage cannot be told apart from one that was stretched.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// The pane content width the stacked Text gallery gets, by viewport:
/// 1280px → 668 − 2 (border) − 48 (pane padding) = 618 — the narrowest row
/// a desktop layout gives,
/// 1440px → 828 − 2 − 48 = 778.
const List<double> _kPaneWidths = [618, 778];

/// `PreviewApp`'s horizontal inset around the example.
const double _kEmbedInset = 16;

/// Layout lands on fractional pixels; a difference under this is not one.
const double _kEpsilon = 0.5;

const ValueKey<String> _kProbe = ValueKey('docs-preview-probe');

const String _kStatusTitle = '상태 색 — 채움마다 짝이 되는 전경색';

/// Every scaling axis at 1, as `PreviewApp` pins them.
final ThemeData _kPreviewTheme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    sizeScaling: 1,
    textScaling: 1,
    radiusScaling: 1,
  ),
);

/// docs_site's `PreviewApp` around [preview] — the same app, scaling and
/// insets.
Widget _embed(Widget preview) => CoUIApp(
  theme: _kPreviewTheme,
  scaling: const AdaptiveScaling(),
  debugShowCheckedModeBanner: false,
  disableBrowserContextMenu: false,
  enableThemeAnimation: false,
  home: Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _kEmbedInset,
        vertical: kDocsPreviewContentInset,
      ),
      child: KeyedSubtree(key: _kProbe, child: preview),
    ),
  ),
);

/// Draws `text/[variant]` on a [width] wide stage and returns the rendered
/// box of the example.
Future<Rect> _drawText(
  WidgetTester tester,
  String variant, {
  required double width,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, docsPreviewConstraintsFor('text', variant).maxHeight);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_embed(kFlutterPreviewRegistry['text']!(variant)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return tester.getRect(find.byKey(_kProbe));
}

void main() {
  setUpAll(_loadDocsFaces);

  for (final width in _kPaneWidths) {
    group('on a ${width}px pane', () {
      testWidgets('colors-brand, which shrinks to its text, is centred', (tester) async {
        // The baseline the detector is read against: if this one fails the
        // measurement is wrong, not the example.
        final box = await _drawText(tester, 'colors-brand', width: width);

        expect(box.width, lessThan(width - 2 * _kEmbedInset - _kEpsilon));
        expect(box.left, closeTo(width - box.right, _kEpsilon));
      });

      testWidgets('colors-status is as wide as its content, not the stage, and is centred', (tester) async {
        final box = await _drawText(tester, 'colors-status', width: width);

        expect(
          box.width,
          lessThan(width - 2 * _kEmbedInset - _kEpsilon),
          reason: 'a swatch row that fills the stage stretches the whole column',
        );
        expect(box.left, closeTo(width - box.right, _kEpsilon));
      });

      testWidgets('the swatches start at the title\'s left edge', (tester) async {
        // Shrinking the block must not move the rows inside it: Web's rows
        // sit at the start of a column as wide as the title.
        await _drawText(tester, 'colors-status', width: width);

        final title = tester.getTopLeft(find.text(_kStatusTitle)).dx;
        final firstSwatch = tester
            .getTopLeft(
              find.ancestor(of: find.text('오류 채움'), matching: find.byType(DecoratedBox)).first,
            )
            .dx;

        expect(firstSwatch, closeTo(title, _kEpsilon));
      });
    });
  }
}

/// Loads the faces the docs embed draws, from `docs_site/fonts`.
Future<void> _loadDocsFaces() async {
  final faces = <String, List<File>>{};
  final directory = Directory('${findRepoRoot().path}/docs_site/fonts');
  for (final file in directory.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    // Static weights only — a variable face needs a weight range.
    if (name.contains('Variable')) continue;
    final family = name.startsWith('Pretendard-')
        ? CoreFontFamily.sans
        : name.startsWith('GeistMono-')
        ? CoreFontFamily.mono
        : null;
    if (family != null) faces.putIfAbsent(family, () => []).add(file);
  }
  expect(faces.keys, containsAll([CoreFontFamily.sans, CoreFontFamily.mono]));

  for (final MapEntry(key: family, value: files) in faces.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
}
