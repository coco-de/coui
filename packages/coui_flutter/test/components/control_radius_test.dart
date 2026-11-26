// The control corner is the control height × 0.25 on every size (디자이너
// 결정 2026-10-08), and hosted rows take their parent’s stated corner. These pin
// what the Flutter widgets paint — the Core test pins the table, this pins
// that the resolvers read it rather than a size-independent constant.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// The control corner is the control height × this.
const double _kRatio = 0.25;

/// The height each size aligns to — from the contract, not from a style row.
const Map<CoreComponentSize, double> _kHeight = {
  CoreComponentSize.xs: CoreControlSize.heightXs,
  CoreComponentSize.sm: CoreControlSize.heightSm,
  CoreComponentSize.md: CoreControlSize.heightMd,
  CoreComponentSize.lg: CoreControlSize.heightLg,
  CoreComponentSize.xl: CoreControlSize.heightXl,
  CoreComponentSize.xl2: CoreControlSize.heightXl2,
};

/// A standalone MenuItem row's corner per size — the `md` row is 36, and
/// 36 × 0.25 = 9 is no corner rung, so it takes 8.
const Map<CoreMenuItemSize, double> _kStandaloneRow = {
  CoreMenuItemSize.sm: CoreRadius.radius8,
  CoreMenuItemSize.md: CoreRadius.radius8,
  CoreMenuItemSize.lg: CoreRadius.radius12,
};

/// The derived hosted row corner, kept by Select on every size.
const double _kHostedRow = CoreRadius.radius6;

/// A Command palette row's highlight — 8 whatever the palette's size (the
/// designer's canvas states 8 for the list row, a little rounder than the
/// 6 that the default derivation gives).
const double _kCommandRow = CoreRadius.radius8;

/// Not 1 — the only density at which a corner that skips `* scaling` and
/// one that takes it come apart.
const double _kScaling = 1.25;

/// One generous frame — enough for an overlay's open motion.
const Duration _kFrame = Duration(seconds: 1);

double _topLeft(Decoration? decoration) => (decoration! as BoxDecoration)
    .borderRadius!
    .resolve(TextDirection.ltr)
    .topLeft
    .x;

/// The field's own box under [host]: the bordered `Container` that is not
/// part of a composed `Button` (the clear / password affordances).
double _fieldBoxRadius(WidgetTester tester, Finder host) {
  final buttonParts = tester
      .widgetList<Container>(
        find.descendant(
          of: find.descendant(of: host, matching: find.byType(Button)),
          matching: find.byType(Container),
        ),
      )
      .toSet();
  final boxes = tester
      .widgetList<Container>(
        find.descendant(of: host, matching: find.byType(Container)),
      )
      .where((c) => !buttonParts.contains(c))
      .where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.border != null && d.borderRadius != null;
      })
      .toList();
  expect(boxes, isNotEmpty, reason: 'the field box moved.');
  return _topLeft(boxes.first.decoration);
}

/// The chrome corner of every `Button` composed under [host].
List<double> _composedButtonRadii(WidgetTester tester, Finder host) => [
  for (final button in tester.elementList(
    find.descendant(of: host, matching: find.byType(Button)),
  ))
    tester
        .widgetList<Container>(
          find.descendant(
            of: find.byElementPredicate((e) => e == button),
            matching: find.byType(Container),
          ),
        )
        .where((c) => c.padding != null)
        .map((c) => _topLeft(c.decoration))
        .single,
];

/// The row box every `MenuItem` on screen paints — its fill and corner.
List<double> _menuItemRadii(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MenuItem),
        matching: find.byType(AnimatedContainer),
      ),
    )
    .map((c) => _topLeft(c.decoration))
    .toList();

Future<void> _pumpScaled(WidgetTester tester, Widget child) => pumpTestApp(
  tester,
  Center(child: child),
  theme: const ThemeData(scaling: _kScaling),
);

void main() {
  group('TextField', () {
    for (final size in CoreComponentSize.values) {
      testWidgets('$size paints its height × 0.25', (tester) async {
        await pumpTestApp(tester, TextField(size: size));
        expect(
          _fieldBoxRadius(tester, find.byType(TextField)),
          _kHeight[size]! * _kRatio,
        );
      });

      testWidgets('$size affordances are no rounder than the field', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          TextField(
            size: size,
            initialValue: 'abc',
            features: const [
              CoreInputFeature.clear(),
              CoreInputFeature.passwordToggle(),
            ],
          ),
        );
        final field = _fieldBoxRadius(tester, find.byType(TextField));
        final affordances = _composedButtonRadii(
          tester,
          find.byType(TextField),
        );
        expect(affordances, hasLength(2), reason: 'clear and password.');
        for (final corner in affordances) {
          expect(corner, lessThanOrEqualTo(field), reason: '$size');
        }
      });
    }

    testWidgets('a caller override still wins over the size row', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        TextField(
          size: CoreComponentSize.xl,
          textFieldStyle: const CoreTextFieldStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ),
      );
      expect(
        _fieldBoxRadius(tester, find.byType(TextField)),
        CoreRadius.radius4,
      );
    });
  });

  group('TextArea', () {
    for (final size in CoreComponentSize.values) {
      testWidgets('$size takes the TextField corner of the same size', (
        tester,
      ) async {
        await pumpTestApp(tester, TextArea(size: size));
        expect(
          _fieldBoxRadius(tester, find.byType(TextArea)),
          _kHeight[size]! * _kRatio,
        );
      });
    }

    testWidgets('a caller override still wins over the size row', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        TextArea(
          size: CoreComponentSize.xl,
          textAreaStyle: const CoreTextAreaStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ),
      );
      expect(
        _fieldBoxRadius(tester, find.byType(TextArea)),
        CoreRadius.radius4,
      );
    });
  });

  group('MenuItem', () {
    for (final size in CoreMenuItemSize.values) {
      testWidgets('standalone $size paints its own corner — 8 · 8 · 12', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          MenuItem(label: const Text('Open'), size: size, onPressed: () {}),
        );
        expect(_menuItemRadii(tester), [_kStandaloneRow[size]!]);
      });

      testWidgets('inside a $size Menu takes the copy’s 8', (tester) async {
        await pumpTestApp(
          tester,
          Menu(
            size: size,
            items: const [
              CoreMenuItem<Widget>.action('Open'),
              CoreMenuItem<Widget>.action('Close'),
            ],
          ),
        );
        expect(_menuItemRadii(tester), [8, 8]);
      });
    }

    testWidgets('a caller override still wins over the size row', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        MenuItem(
          label: const Text('Open'),
          size: CoreMenuItemSize.lg,
          onPressed: () {},
          menuItemStyle: const CoreMenuItemStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ),
      );
      expect(_menuItemRadii(tester), [
        CoreRadius.radius4,
      ]);
    });

    testWidgets('the corner scales with the height, once', (tester) async {
      await _pumpScaled(
        tester,
        MenuItem(label: const Text('Open'), onPressed: () {}),
      );
      expect(_menuItemRadii(tester), [
        _kStandaloneRow[CoreMenuItemSize.md]! * _kScaling,
      ]);
    });
  });

  group('Menu hosted corners (#5967)', () {
    for (final size in CoreMenuItemSize.values) {
      testWidgets('horizontal $size paints the copy’s 8', (tester) async {
        await pumpTestApp(
          tester,
          Menu(
            size: size,
            vertical: false,
            items: const [CoreMenuItem<Widget>.action('Open')],
          ),
        );
        expect(_menuItemRadii(tester), [8]);
      });
    }

    testWidgets('theme and instance row overrides survive partial slots', (
      tester,
    ) async {
      const componentTheme = CoreComponentTheme(
        menu: CoreMenuTheme(
          style: CoreMenuStyle(
            itemStyle: CoreMenuItemStyle(
              borderRadius: CoreBorderRadius.all(4),
            ),
          ),
        ),
      );
      for (final corner in [null, 10.0]) {
        // The helper’s Overlay.initialEntries are installed only on mount.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpTestApp(
          tester,
          Menu(
            items: const [CoreMenuItem<Widget>.action('Open')],
            menuStyle: CoreMenuStyle(
              itemStyle: CoreMenuItemStyle(
                padding: const CoreEdgeInsets.all(6),
                borderRadius: corner == null
                    ? null
                    : CoreBorderRadius.all(corner),
              ),
            ),
          ),
          componentTheme: componentTheme,
        );
        await tester.pumpAndSettle();
        expect(_menuItemRadii(tester), [corner ?? 4]);
      }
    });

    testWidgets('inline child resolves its own default and nested override', (
      tester,
    ) async {
      for (final corner in [null, 2.0]) {
        // Remount so the preceding child's expanded state cannot carry over.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpTestApp(
          tester,
          Menu(
            items: const [
              CoreMenuItem<Widget>.action(
                'More',
                submenu: [CoreMenuItem<Widget>.action('Settings')],
              ),
            ],
            menuStyle: CoreMenuStyle(
              itemStyle: const CoreMenuItemStyle(
                borderRadius: CoreBorderRadius.all(4),
              ),
              submenuStyle: CoreMenuStyle(
                itemStyle: corner == null
                    ? null
                    : CoreMenuItemStyle(
                        borderRadius: CoreBorderRadius.all(corner),
                      ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        expect(_menuItemRadii(tester), [4, corner ?? 8]);
      }
    });
  });

  group('Select', () {
    for (final size in CoreSelectSize.values) {
      testWidgets('$size options are 6', (tester) async {
        await pumpTestApp(
          tester,
          Select<String>(
            size: size,
            onChanged: (_) {},
            placeholder: 'Pick',
            items: const [
              CoreSelectItem<String>(value: 'apple', label: 'Apple'),
              CoreSelectItem<String>(value: 'banana', label: 'Banana'),
            ],
          ),
        );
        await tester.tap(find.byType(TextField));
        await tester.pump(_kFrame);
        final rows = _menuItemRadii(tester);
        expect(rows, isNotEmpty, reason: 'the panel did not open.');
        expect(rows.toSet(), {_kHostedRow}, reason: '$size');
      });
    }
  });

  group('Command', () {
    for (final presentation in CoreCommandPresentation.values) {
      for (final size in CoreCommandSize.values) {
        testWidgets('$presentation $size rows are 8', (tester) async {
          late ResolvedCommand resolved;
          await pumpTestApp(
            tester,
            Builder(
              builder: (context) {
                resolved = resolveCommand(
                  context,
                  presentation: presentation,
                  size: size,
                );
                return const SizedBox.shrink();
              },
            ),
          );
          expect(resolved.itemBorderRadius.topLeft.x, _kCommandRow);
        });
      }
    }

    testWidgets('inline and dialog lists inset their rows 8; the dialog panel '
        'is the modal corner', (tester) async {
      late ResolvedCommand inline;
      late ResolvedCommand dialog;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            inline = resolveCommand(context);
            dialog = resolveCommand(context, presentation: .dialog);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(inline.listPadding, const EdgeInsets.all(8));
      expect(dialog.listPadding, const EdgeInsets.all(8));
      expect(
        dialog.panelContainerStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.modal),
      );
    });

    testWidgets('the shortcut and the footer hint are the bodyXs role and the '
        'heading is labelXs at weight 500', (tester) async {
      late ResolvedCommand resolved;
      late CoreTypography typography;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveCommand(context);
            typography = Theme.of(context).typography;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved.shortcutTextStyle.fontSize, typography.bodyXs.fontSize);
      // The same face as the body-role footer hint — not the code face.
      expect(
        resolved.shortcutTextStyle.fontFamily,
        resolved.footerTextStyle.fontFamily,
      );
      expect(resolved.footerTextStyle.fontSize, typography.bodyXs.fontSize);
      expect(resolved.headingTextStyle.fontSize, typography.labelXs.fontSize);
      expect(resolved.headingTextStyle.fontWeight, FontWeight.w500);
      // The role's own tracking — nothing is laid over it.
      expect(
        resolved.headingTextStyle.letterSpacing,
        closeTo(
          typography.labelXs.letterSpacing! * typography.labelXs.fontSize!,
          1e-9,
        ),
      );
    });

    testWidgets('the row corner scales with the row height, once', (
      tester,
    ) async {
      late ResolvedCommand resolved;
      await _pumpScaled(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveCommand(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved.itemBorderRadius.topLeft.x, _kCommandRow * _kScaling);
      expect(
        resolved.itemMinHeight,
        CoreCommandStyle.defaultItemMinHeight * _kScaling,
      );
    });
  });
}
