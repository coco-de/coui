import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The control corner is the control height × this (디자이너 결정
/// 2026-10-08) — one ratio on every size, not one value.
const double _kRatio = 0.25;

/// The height each size aligns to. Stated here, from the contract, rather
/// than read off the style row, so the test checks the paint against the
/// rule and not against the table that produced it.
const Map<CoreComponentSize, double> _kHeight = {
  CoreComponentSize.xs: CoreControlSize.heightXs,
  CoreComponentSize.sm: CoreControlSize.heightSm,
  CoreComponentSize.md: CoreControlSize.heightMd,
  CoreComponentSize.lg: CoreControlSize.heightLg,
  CoreComponentSize.xl: CoreControlSize.heightXl,
  CoreComponentSize.xl2: CoreControlSize.heightXl2,
};

/// Not 1 — the only density at which a corner that skips `* scaling` and
/// one that takes it come apart.
const double _kScaling = 1.25;

/// The button's chrome container — the one that carries padding (the
/// focus ring and cast boxes state none). Same identification as
/// `button_test.dart`, restated here so this file stands on its own.
Container _chromeContainer(WidgetTester tester) {
  final padded = tester
      .widgetList<Container>(find.byType(Container))
      .where((container) => container.padding != null)
      .toList();
  expect(padded, hasLength(1), reason: 'the chrome container moved.');
  return padded.single;
}

double _chromeRadius(WidgetTester tester) =>
    (_chromeContainer(tester).decoration! as BoxDecoration).borderRadius!
        .resolve(TextDirection.ltr)
        .topLeft
        .x;

/// The raw corner the button hands its `FocusOutline` — the host radius
/// the band and the ring are derived from.
double _ringHostRadius(WidgetTester tester) => tester
    .widget<FocusOutline>(
      find
          .descendant(
            of: find.byType(Button),
            matching: find.byType(FocusOutline),
          )
          .first,
    )
    .focusOutlineStyle!
    .borderRadius!
    .topLeft;

/// Outer corner radius of each layer a `FocusOutline` paints — the band
/// (offset, a shape stroke) and the ring (a bordered box), in child order.
List<double> _outlineRadii(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FocusOutline),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map(
      (d) => switch (d.decoration) {
        BoxDecoration(:final borderRadius?) => borderRadius,
        ShapeDecoration(
          shape: RoundedRectangleBorder(:final borderRadius),
        ) =>
          borderRadius,
        _ => null,
      },
    )
    .nonNulls
    .map((r) => r.resolve(TextDirection.ltr).topLeft.x)
    .toList();

Future<void> _pumpFocusOutline(WidgetTester tester, double host) => pumpTestApp(
  tester,
  FocusOutline(
    focused: true,
    // The band paints only when a colour is stated — Button seeds it
    // from its own slot; a bare outline is asked for it here.
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(host),
      offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
    ),
    child: const SizedBox(width: 80, height: 32),
  ),
);

void main() {
  group('control corner — Button (Flutter)', () {
    for (final size in CoreComponentSize.values) {
      testWidgets('$size paints its height × 0.25', (tester) async {
        await pumpTestApp(
          tester,
          Button(onPressed: () {}, size: size, child: const Text('X')),
        );
        expect(
          _chromeRadius(tester),
          _kHeight[size]! * _kRatio,
          reason: 'the corner is one ratio of the control height.',
        );
      });

      testWidgets('$size square takes the same corner', (tester) async {
        await pumpTestApp(
          tester,
          Button(
            onPressed: () {},
            size: size,
            shape: CoreButtonShape.square,
            child: const Icon(LucideIcons.plus),
          ),
        );
        expect(_chromeRadius(tester), _kHeight[size]! * _kRatio);
      });

      testWidgets('$size hands its corner to the focus ring', (tester) async {
        await pumpTestApp(
          tester,
          Button(onPressed: () {}, size: size, child: const Text('X')),
        );
        // The ring is derived from what it is handed — band R + 2, ring
        // R + 4 — so handing it the chrome's corner is what keeps the
        // three concentric on every size.
        expect(_ringHostRadius(tester), _kHeight[size]! * _kRatio);
      });
    }

    testWidgets('circle keeps the pill', (tester) async {
      await pumpTestApp(
        tester,
        Button(
          onPressed: () {},
          shape: CoreButtonShape.circle,
          child: const Text('X'),
        ),
      );
      expect(
        _chromeRadius(tester),
        greaterThan(CoreControlSize.heightXl2 * _kRatio),
      );
    });

    testWidgets('a caller override still wins over the size row', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Button(
          onPressed: () {},
          size: CoreComponentSize.lg,
          buttonStyle: const CoreButtonStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
          child: const Text('X'),
        ),
      );
      expect(_chromeRadius(tester), CoreRadius.radius4);
    });

    testWidgets('the corner scales with the height, once', (tester) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(scaling: _kScaling),
            child: material.Center(
              child: Button(onPressed: () {}, child: const Text('X')),
            ),
          ),
        ),
      );
      expect(
        _chromeRadius(tester),
        CoreControlSize.heightMd * _kRatio * _kScaling,
      );
    });
  });

  group('FocusOutline derives band / ring from the host', () {
    testWidgets('host 10 (md) → band 12, ring 14', (tester) async {
      await _pumpFocusOutline(tester, CoreRadius.radius10);
      final radii = _outlineRadii(tester);
      expect(radii, hasLength(2), reason: 'band then ring.');
      expect(radii, [12, 14]);
    });

    testWidgets('host 16 (xl2) → band 18, ring 20 (computed, not a table)', (
      tester,
    ) async {
      await _pumpFocusOutline(tester, CoreRadius.radius16);
      expect(_outlineRadii(tester), [18, 20]);
    });
  });

  group('Fieldset (Flutter)', () {
    testWidgets('stays 16 (the surface role) whatever the fields inside', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          legend: Text('L'),
          children: [SizedBox(width: 80, height: 32)],
        ),
      );
      final radii = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.borderRadius != null)
          .map((d) => d.borderRadius!.resolve(TextDirection.ltr).topLeft.x)
          .toSet();
      expect(radii, contains(CoreRadiusRole.surface));
      expect(radii, isNot(contains(CoreRadius.radius24)));
    });
  });
}
