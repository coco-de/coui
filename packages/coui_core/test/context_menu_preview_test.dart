// A ContextMenu's preview goes around the menu where the menu ended up, by one
// rule in Core (`CoreContextMenuPreview.place`) that both seats read. This
// file pins the rule against the shared table's exact cases and against the
// properties the rule promises for any input — the preview is never over the
// menu, never outside the viewport and never farther than the gap — and checks
// the table's scenarios, which the Flutter and Web tests replay on real menus,
// are well formed.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web ContextMenu tests and the
/// Chrome probe.
const String kContextMenuPreviewVectorsPath =
    'test/fixtures/context_menu_preview_vectors.json';

CoreMenuBox _box(Object? edges) {
  final e = (edges! as List).cast<num>().map((v) => v.toDouble()).toList();

  return CoreMenuBox(left: e[0], top: e[1], right: e[2], bottom: e[3]);
}

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

CoreTextDirection _direction(Map<String, Object?> vector) =>
    vector['direction'] == 'rtl' ? .rtl : .ltr;

CorePreviewSide _side(Object? name) =>
    CorePreviewSide.values.byName(name! as String);

void main() {
  final doc =
      jsonDecode(File(kContextMenuPreviewVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = _list(doc['cases']);
  final scenarios = _list(doc['scenarios']);

  CorePreviewPlacement place(Map<String, Object?> vector) {
    final preview = (vector['preview']! as List).cast<num>();

    return CoreContextMenuPreview.place(
      menu: _box(vector['menu']),
      previewWidth: preview[0].toDouble(),
      previewHeight: preview[1].toDouble(),
      viewport: _box(vector['viewport']),
      gap:
          (vector['gap'] as num?)?.toDouble() ??
          CoreContextMenuContract.defaultPreviewGap,
      direction: _direction(vector),
    );
  }

  group('the gap', () {
    test('is the 8 px grid step', () {
      expect(CoreContextMenuContract.defaultPreviewGap, 8);
      expect(CoreContextMenuContract.defaultPreviewGap, CoreSpace.space8);
    });

    test('the table states the number it was written against', () {
      expect(
        (doc['gap']! as num).toDouble(),
        CoreContextMenuContract.defaultPreviewGap,
      );
    });
  });

  group('CoreContextMenuPreview.place against the vectors', () {
    test('the table is not empty', () {
      expect(cases, isNotEmpty);
      expect(scenarios, isNotEmpty);
    });

    for (final vector in cases) {
      test(vector['name']! as String, () {
        final placed = place(vector);
        final expected = vector['expect']! as Map<String, Object?>;
        expect(placed.side, _side(expected['side']));
        expect(placed.box, _box(expected['box']));
        expect(placed.capped, expected['capped']);
        expect(placed.visible, expected['visible']);
      });
    }
  });

  group('the promises, for every case in the table', () {
    for (final vector in cases) {
      test(vector['name']! as String, () {
        final placed = place(vector);
        if (!placed.visible) return;

        final menu = _box(vector['menu']);
        final viewport = _box(vector['viewport']);
        final gap =
            (vector['gap'] as num?)?.toDouble() ??
            CoreContextMenuContract.defaultPreviewGap;

        expect(
          placed.box.intersect(menu),
          isNull,
          reason: 'never over the menu',
        );
        expect(placed.box.left, greaterThanOrEqualTo(viewport.left));
        expect(placed.box.top, greaterThanOrEqualTo(viewport.top));
        expect(placed.box.right, lessThanOrEqualTo(viewport.right));
        expect(placed.box.bottom, lessThanOrEqualTo(viewport.bottom));

        // The distance along the side's own axis is exactly the gap.
        final rtl = vector['direction'] == 'rtl';
        switch (placed.side) {
          case CorePreviewSide.above:
            expect(menu.top - placed.box.bottom, gap);
          case CorePreviewSide.below:
            expect(placed.box.top - menu.bottom, gap);
          case CorePreviewSide.end when !rtl:
          case CorePreviewSide.start when rtl:
            expect(placed.box.left - menu.right, gap);
          case CorePreviewSide.end:
          case CorePreviewSide.start:
            expect(menu.left - placed.box.right, gap);
        }
      });
    }
  });

  group('the rule', () {
    const viewport = CoreMenuBox(left: 0, top: 0, right: 400, bottom: 800);
    const menu = CoreMenuBox(left: 100, top: 400, right: 360, bottom: 500);

    test('prefers above to below when both hold the preview', () {
      final placed = CoreContextMenuPreview.place(
        menu: menu,
        previewWidth: 100,
        previewHeight: 100,
        viewport: viewport,
      );
      expect(placed.side, CorePreviewSide.above);
    });

    test('prefers a vertical side to a side beside the menu', () {
      final placed = CoreContextMenuPreview.place(
        menu: const CoreMenuBox(left: 100, top: 400, right: 200, bottom: 500),
        previewWidth: 100,
        previewHeight: 100,
        viewport: viewport,
      );
      expect(placed.side, CorePreviewSide.above);
    });

    test('a preview that fits keeps its natural size', () {
      final placed = CoreContextMenuPreview.place(
        menu: menu,
        previewWidth: 123,
        previewHeight: 45,
        viewport: viewport,
      );
      expect(placed.box.width, 123);
      expect(placed.box.height, 45);
      expect(placed.capped, isFalse);
    });

    test('right-to-left swaps what end and start mean and nothing else', () {
      const wide = CoreMenuBox(left: 0, top: 0, right: 1000, bottom: 300);
      const tight = CoreMenuBox(left: 400, top: 20, right: 660, bottom: 140);
      final ltr = CoreContextMenuPreview.place(
        menu: tight,
        previewWidth: 200,
        previewHeight: 280,
        viewport: wide,
      );
      final rtl = CoreContextMenuPreview.place(
        menu: tight,
        previewWidth: 200,
        previewHeight: 280,
        viewport: wide,
        direction: CoreTextDirection.rtl,
      );
      expect(ltr.side, CorePreviewSide.end);
      expect(rtl.side, CorePreviewSide.end);
      expect(ltr.box.left, greaterThan(tight.right), reason: 'right of it');
      expect(rtl.box.right, lessThan(tight.left), reason: 'left of it');
      expect(ltr.box.top, rtl.box.top);
    });

    test('equal placements are equal', () {
      CorePreviewPlacement make() => CoreContextMenuPreview.place(
        menu: menu,
        previewWidth: 200,
        previewHeight: 120,
        viewport: viewport,
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });
  });

  group('the scenarios', () {
    const sides = {'above', 'below', 'end', 'start'};
    const physicals = {'above', 'below', 'left', 'right'};

    for (final scenario in scenarios) {
      test(scenario['name']! as String, () {
        expect(sides, contains(scenario['side']));
        expect(physicals, contains(scenario['physical']));
        expect(scenario['viewport']! as List, hasLength(2));
        expect(scenario['pointer']! as List, hasLength(2));
        expect(scenario['preview']! as List, hasLength(2));
        expect(scenario['rows'], isA<int>());
      });
    }

    test('each answer holds for the menus a real seat lays out', () {
      // The seats' menus differ from one another by a few px, so a scenario
      // is only worth replaying if the rule gives the same answer for the
      // smallest and the largest menu it could meet. The menu is the one a
      // real seat would open: its top-left corner at the pointer, moved just
      // far enough to stay inside the margin.
      for (final scenario in scenarios) {
        final vp = (scenario['viewport']! as List).cast<num>();
        final pointer = (scenario['pointer']! as List).cast<num>();
        final preview = (scenario['preview']! as List).cast<num>();
        final viewport = CoreMenuBox(
          left: 8,
          top: 8,
          right: vp[0].toDouble() - 8,
          bottom: vp[1].toDouble() - 8,
        );
        for (final size in const [(240.0, 110.0), (280.0, 140.0)]) {
          var left = pointer[0].toDouble();
          var top = pointer[1].toDouble();
          if (left + size.$1 > viewport.right) left = viewport.right - size.$1;
          if (top + size.$2 > viewport.bottom) top = viewport.bottom - size.$2;
          final placed = CoreContextMenuPreview.place(
            menu: CoreMenuBox.fromLTWH(left, top, size.$1, size.$2),
            previewWidth: preview[0].toDouble(),
            previewHeight: preview[1].toDouble(),
            viewport: viewport,
            direction: _direction(scenario),
          );
          expect(
            placed.side,
            _side(scenario['side']),
            reason: '${scenario['name']} with a $size menu',
          );
        }
      }
    });
  });
}
