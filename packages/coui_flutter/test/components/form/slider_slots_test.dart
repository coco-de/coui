import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kTrackWidth = 300.0;
const _kLeadingKey = Key('leading');
const _kTrailingKey = Key('trailing');
const _kSlotSize = 24.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kTrackWidth,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

void main() {
  group('Slider fills the parent width', () {
    // 디자이너 확인: 캔버스의 240 은 보여 주기 위한 폭이고, 코드는 부모 폭을 채운다.
    for (final parentWidth in [_kTrackWidth, 180.0]) {
      testWidgets('track spans a parent of $parentWidth (no slots)', (
        tester,
      ) async {
        await tester.pumpWidget(
          material.MaterialApp(
            home: material.Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: material.SizedBox(
                  width: parentWidth,
                  child: Theme(
                    data: const ThemeData(),
                    child: Slider(onChanged: (_) {}, value: 50),
                  ),
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final padding = CoreSliderStyle.defaultContainerPadding;
        final horizontal = padding.left + padding.right;
        expect(tester.getSize(find.byType(Slider)).width, parentWidth);
        expect(
          tester
              .getSize(
                find.descendant(
                  of: find.byType(Slider),
                  matching: find.byType(TouchTarget),
                ),
              )
              .width,
          parentWidth - horizontal,
        );
      });
    }
  });

  group('Slider leading / trailing slots', () {
    testWidgets('draws nothing and no gap when both are null', (tester) async {
      await tester.pumpWidget(_buildApp(Slider(onChanged: (_) {}, value: 50)));
      final _ = await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(Slider), matching: find.byType(Row)),
        findsNothing,
      );
    });

    testWidgets('lays leading before and trailing after the track, one gap '
        'apart', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Slider(
            onChanged: (_) {},
            value: 50,
            leading: const SizedBox(key: _kLeadingKey, width: _kSlotSize),
            trailing: const SizedBox(key: _kTrailingKey, width: _kSlotSize),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final leading = tester.getRect(find.byKey(_kLeadingKey));
      final trailing = tester.getRect(find.byKey(_kTrailingKey));
      final track = tester.getRect(
        find.descendant(
          of: find.byType(Slider),
          matching: find.byType(TouchTarget),
        ),
      );
      final gap = CoreSliderStyle.defaultSlotGapStyle.size!;

      expect(leading.right + gap, track.left);
      expect(track.right + gap, trailing.left);
    });

    testWidgets('a tap on the track still maps over the narrowed track', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(
        _buildApp(
          Slider(
            onChanged: (v) => changed = v,
            leading: const SizedBox(width: _kSlotSize),
            trailing: const SizedBox(width: _kSlotSize),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final track = tester.getRect(
        find.descendant(
          of: find.byType(Slider),
          matching: find.byType(TouchTarget),
        ),
      );
      await tester.tapAt(track.center);
      final __ = await tester.pumpAndSettle();

      expect(changed, closeTo(50, 1));
    });
  });

  group('Slider thumb', () {
    testWidgets('casts the smallest shadow step', (tester) async {
      await tester.pumpWidget(_buildApp(Slider(onChanged: (_) {}, value: 50)));
      final _ = await tester.pumpAndSettle();

      final thumbs = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(FocusOutline),
              matching: find.byType(Container),
            ),
          )
          .where((c) => c.decoration is BoxDecoration)
          .map((c) => (c.decoration! as BoxDecoration).boxShadow)
          .whereType<List<BoxShadow>>()
          .toList();

      expect(thumbs, hasLength(1));
      expect(thumbs.single, hasLength(CoreShadow.xs.length));
      expect(thumbs.single.first.blurRadius, isNonZero);
    });

    testWidgets('the focus ring wraps the thumb, not the whole track', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(Slider(onChanged: (_) {}, value: 50)));
      final _ = await tester.pumpAndSettle();

      final ring = tester.getSize(find.byType(FocusOutline));
      expect(ring.width, CoreSliderStyle.defaultThumbSize);
    });
  });
}
