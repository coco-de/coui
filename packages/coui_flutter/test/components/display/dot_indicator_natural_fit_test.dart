import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _kIndicatorKey = ValueKey('indicator');
const _kLength = 5;
const _kNaturalMediumExtent = 88.0;

Future<void> _pumpIndicator(
  WidgetTester tester, {
  CoreAxis axis = CoreAxis.horizontal,
  BoxConstraints constraints = const BoxConstraints(maxWidth: 88),
  CoreDotIndicatorStyle? style,
  CoreDotIndicatorStyle? themeStyle,
  CoreDotIndicatorSize size = CoreDotIndicatorSize.defaultSize,
  int length = _kLength,
  int index = 2,
  bool rtl = false,
  String? intrinsic,
  bool settle = true,
}) async {
  Widget child = DotIndicator(
    key: _kIndicatorKey,
    length: length,
    index: index,
    direction: axis,
    size: size,
    onChanged: (_) {},
    dotIndicatorStyle: style,
  );
  if (intrinsic == 'width') child = IntrinsicWidth(child: child);
  if (intrinsic == 'height') child = IntrinsicHeight(child: child);
  await tester.pumpWidget(
    widgets.WidgetsApp(
      color: const Color(0xff000000),
      builder: (context, _) => Theme(
        data: ThemeData(
          coreComponentTheme: CoreComponentTheme(
            dotIndicator: CoreDotIndicatorTheme(style: themeStyle),
          ),
        ),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(constraints: constraints, child: child),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

List<Rect> _dots(WidgetTester tester) {
  final root = find.byKey(_kIndicatorKey);
  final rootBox = tester.renderObject<RenderBox>(root);
  return find
      .descendant(of: root, matching: find.byType(AnimatedContainer))
      .evaluate()
      .map((element) {
        final box = element.renderObject! as RenderBox;
        return box.localToGlobal(Offset.zero, ancestor: rootBox) & box.size;
      })
      .toList();
}

List<Size> _dotSizes(WidgetTester tester) => find
    .descendant(
      of: find.byKey(_kIndicatorKey),
      matching: find.byType(AnimatedContainer),
    )
    .evaluate()
    .map((element) => (element.renderObject! as RenderBox).size)
    .toList();

RenderFlex _flex(WidgetTester tester) => tester.renderObject<RenderFlex>(
  find
      .descendant(
        of: find.byKey(_kIndicatorKey),
        matching: find.byType(Flex),
      )
      .first,
);

BoxConstraints _cap(CoreAxis axis, double extent) => axis == CoreAxis.horizontal
    ? BoxConstraints(maxWidth: extent, maxHeight: 200)
    : BoxConstraints(maxWidth: 200, maxHeight: extent);

double _main(Size size, CoreAxis axis) =>
    axis == CoreAxis.horizontal ? size.width : size.height;

void main() {
  for (final axis in CoreAxis.values) {
    testWidgets(
      '$axis preserves natural medium geometry at its exact main cap',
      (tester) async {
        await _pumpIndicator(tester, axis: axis, constraints: _cap(axis, 88));
        expect(
          _main(tester.getSize(find.byKey(_kIndicatorKey)), axis),
          _kNaturalMediumExtent,
        );
        expect(
          _dotSizes(tester),
          everyElement(const Size(8, 8)),
        );
      },
    );

    for (final size in CoreDotIndicatorSize.values) {
      testWidgets('$axis $size preserves the existing size rung', (
        tester,
      ) async {
        final row = CoreDotIndicatorStyle.defaultsBySize[size]!;
        final diameter = row.dotSize!;
        final extent = diameter * _kLength + row.spacing! * (_kLength - 1) + 16;
        await _pumpIndicator(
          tester,
          axis: axis,
          size: size,
          constraints: _cap(axis, extent),
        );
        expect(_main(tester.getSize(find.byKey(_kIndicatorKey)), axis), extent);
        expect(
          _dotSizes(tester),
          everyElement(Size.square(diameter)),
        );
      });
    }

    testWidgets('$axis keeps the original too-narrow layout', (tester) async {
      await _pumpIndicator(tester, axis: axis, constraints: _cap(axis, 87.75));
      final slots = _flex(tester);
      expect(
        axis == CoreAxis.horizontal
            ? slots.constraints.maxWidth
            : slots.constraints.maxHeight,
        87.75,
      );
      final dots = _dotSizes(tester);
      final expected = axis == CoreAxis.horizontal
          ? const Size(5.550000000000001, 8)
          : const Size(8, 5.550000000000001);
      expect(dots.first, expected);
      expect(dots.last, expected);
      expect(dots[1], const Size(8, 8));
      expect(_main(tester.getSize(find.byKey(_kIndicatorKey)), axis), 83.1);
    });

    testWidgets('$axis preserves fractional bounds and incoming minimum', (
      tester,
    ) async {
      for (final extent in [88.25, 96.25]) {
        final constraints = axis == CoreAxis.horizontal
            ? BoxConstraints(
                minWidth: extent,
                maxWidth: extent,
                minHeight: 31,
                maxHeight: 31,
              )
            : BoxConstraints(
                minHeight: extent,
                maxHeight: extent,
                minWidth: 31,
                maxWidth: 31,
              );
        await _pumpIndicator(tester, axis: axis, constraints: constraints);
        expect(
          constraints.isSatisfiedBy(tester.getSize(find.byKey(_kIndicatorKey))),
          isTrue,
        );
        expect(
          _dotSizes(tester),
          everyElement(const Size(8, 8)),
        );
      }
    });

    testWidgets('$axis supports intrinsic callers and consistent dry layout', (
      tester,
    ) async {
      for (final intrinsic in ['width', 'height']) {
        await _pumpIndicator(
          tester,
          axis: axis,
          constraints: const BoxConstraints(maxWidth: 180, maxHeight: 180),
          intrinsic: intrinsic,
        );
        expect(
          _dotSizes(tester),
          everyElement(const Size(8, 8)),
        );
      }
      final root = tester.renderObject<RenderBox>(find.byKey(_kIndicatorKey));
      final dry = root.getDryLayout(_cap(axis, 88));
      expect(_main(dry, axis), 88);
      expect(
        root.getDryBaseline(_cap(axis, 88), TextBaseline.alphabetic),
        isNull,
      );
      expect(
        axis == CoreAxis.horizontal
            ? root.getMaxIntrinsicWidth(100)
            : root.getMaxIntrinsicHeight(100),
        100,
      );
    });

    testWidgets('$axis retains RTL asymmetric padding and active length', (
      tester,
    ) async {
      const style = CoreDotIndicatorStyle(
        dotSize: 8,
        activeLength: 20,
        spacing: 8,
        padding: CoreEdgeInsets.only(left: 3, right: 5, top: 10, bottom: 14),
      );
      final extent = axis == CoreAxis.horizontal ? 92.0 : 108.0;
      await _pumpIndicator(
        tester,
        axis: axis,
        constraints: _cap(axis, extent),
        rtl: true,
        style: style,
      );
      expect(_main(tester.getSize(find.byKey(_kIndicatorKey)), axis), extent);
      final dots = _dots(tester);
      expect(
        dots[2].size,
        axis == CoreAxis.horizontal ? const Size(20, 8) : const Size(8, 20),
      );
      if (axis == CoreAxis.horizontal) {
        expect(dots.first.left - dots[1].right, 8);
        expect(dots.last.left, 3);
      } else {
        expect(dots[1].top - dots.first.bottom, 8);
        expect(dots.first.top, 10);
      }
    });

    testWidgets(
      '$axis measures actual dimensions during inherited size motion',
      (
        tester,
      ) async {
        for (final ramp in [
          [12.0, 8.0],
          [8.0, 12.0],
        ]) {
          await _pumpIndicator(
            tester,
            axis: axis,
            constraints: _cap(axis, 88),
            themeStyle: CoreDotIndicatorStyle(dotSize: ramp[0]),
          );
          await _pumpIndicator(
            tester,
            axis: axis,
            constraints: _cap(axis, 88),
            themeStyle: CoreDotIndicatorStyle(dotSize: ramp[1]),
            settle: false,
          );
          await tester.pump(const Duration(milliseconds: 50));
          final current = _dotSizes(tester).first;
          final cross = axis == CoreAxis.horizontal
              ? current.height
              : current.width;
          expect(cross, inExclusiveRange(8, 12));
          expect(
            axis == CoreAxis.horizontal
                ? _flex(tester).constraints.maxWidth
                : _flex(tester).constraints.maxHeight,
            88,
          );
          await tester.pumpAndSettle();
          if (ramp[1] == 8) {
            expect(
              _dotSizes(tester),
              everyElement(const Size(8, 8)),
            );
            expect(_main(tester.getSize(find.byKey(_kIndicatorKey)), axis), 88);
          }
        }
      },
    );

    testWidgets('$axis keeps zero/one counts and invalid index geometry', (
      tester,
    ) async {
      for (final length in [0, 1, 3]) {
        final extent = length == 0
            ? 0.0
            : length * 8.0 + (length - 1) * 8.0 + 16.0;
        await _pumpIndicator(
          tester,
          axis: axis,
          length: length,
          index: -1,
          constraints: _cap(axis, extent),
        );
        expect(_dots(tester), hasLength(length));
        expect(_main(tester.getSize(find.byKey(_kIndicatorKey)), axis), extent);
        expect(
          _dotSizes(tester),
          everyElement(const Size(8, 8)),
        );
      }
    });
  }
}
