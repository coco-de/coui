import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kBorderWidth = 2.0;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

Finder _iconFinder(IconName name) =>
    find.byWidgetPredicate((widget) => widget is Icon && widget.icon == name);

/// Resolves a chip at [size] under the default theme, returning the theme too
/// so a scaled value can be compared with its row.
Future<({ResolvedChip resolved, ThemeData theme})> _resolve(
  WidgetTester tester,
  CoreChipSize size, {
  CoreChipStyle? chipStyle,
}) async {
  late ResolvedChip resolved;
  late ThemeData theme;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            theme = Theme.of(context);
            resolved = resolveChip(
              context,
              variant: CoreChipVariant.outlined,
              chipColor: CoreChipColor.neutral,
              emphasis: CoreChipEmphasis.high,
              size: size,
              selected: false,
              enabled: true,
              chipStyle: chipStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (resolved: resolved, theme: theme);
}

void main() {
  group('Chip size rows reach the resolved chrome', () {
    testWidgets('the face, the cast and the focus ring take the row corner', (
      tester,
    ) async {
      // 6 · 8 · 10 — one corner, read once, so the three can never part.
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        final r = await _resolve(tester, size);
        final corner = row.borderRadius!;
        expect(
          r.resolved.containerStyle.borderRadius,
          corner,
          reason: '${size.name} face',
        );
        expect(
          r.resolved.hoverContainerStyle.borderRadius,
          corner,
          reason: '${size.name} wash',
        );
        expect(
          r.resolved.castBorderRadius.topLeft.x,
          corner.topLeft,
          reason: '${size.name} cast',
        );
        expect(
          r.resolved.clickableStyle.borderRadius,
          corner,
          reason: '${size.name} focus ring',
        );
        // A size row's corner, not the pill.
        expect(corner.topLeft, lessThan(CoreRadius.radius9999));
      }
    });

    testWidgets('a corner the caller states moves the ring with the face', (
      tester,
    ) async {
      const pill = CoreBorderRadius.all(CoreRadius.radius9999);
      for (final size in CoreChipSize.values) {
        final r = await _resolve(
          tester,
          size,
          chipStyle: const CoreChipStyle(borderRadius: pill),
        );
        expect(r.resolved.containerStyle.borderRadius, pill, reason: size.name);
        expect(r.resolved.clickableStyle.borderRadius, pill, reason: size.name);
      }
    });

    testWidgets('a clickableStyle corner still wins over the face corner', (
      tester,
    ) async {
      const ring = CoreBorderRadius.all(CoreRadius.radius4);
      final r = await _resolve(
        tester,
        CoreChipSize.md,
        chipStyle: const CoreChipStyle(
          clickableStyle: CoreClickableStyle(borderRadius: ring),
        ),
      );
      expect(r.resolved.clickableStyle.borderRadius, ring);
      // The face keeps the row's corner.
      expect(
        r.resolved.containerStyle.borderRadius,
        CoreChipStyle.defaultsBySize[CoreChipSize.md]!.borderRadius,
      );
    });

    testWidgets(
      'the small chip keeps its close button no rounder than itself',
      (
        tester,
      ) async {
        // `Button` sm draws 8; the sm chip is 6. The row states the chip's
        // corner on the button there, and states nothing where the button's
        // own is already no rounder (md 8 = 8, lg 10 > 8).
        final sm = await _resolve(tester, CoreChipSize.sm);
        expect(
          sm.resolved.closeButtonStyle?.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius6),
        );
        for (final size in [CoreChipSize.md, CoreChipSize.lg]) {
          final r = await _resolve(tester, size);
          expect(r.resolved.closeButtonStyle?.borderRadius, isNull);
        }
      },
    );

    testWidgets('padding and leading / trailing icons are the row values', (
      tester,
    ) async {
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        final r = await _resolve(tester, size);
        final scaling = r.theme.scaling;
        expect(
          r.resolved.leadingIconSize,
          row.leadingIconStyle!.size! * scaling,
          reason: '${size.name} leading',
        );
        expect(
          r.resolved.trailingIconSize,
          row.trailingIconStyle!.size! * scaling,
          reason: '${size.name} trailing',
        );
        expect(
          r.resolved.containerStyle.padding,
          row.padding,
          reason: '${size.name} padding',
        );
      }
    });
  });

  group('CoreChipStyle', () {
    test('default constructor creates style with null values', () {
      const style = CoreChipStyle();

      expect(style.borderRadius, isNull);
      expect(style.backgroundColor, isNull);
      expect(style.borderColor, isNull);
    });

    test('copyWith creates modified copy', () {
      const style = CoreChipStyle(borderWidth: _kBorderWidth);
      final copied = style.copyWith(
        backgroundColor: const CoreColor(0xFFFF0000),
      );

      expect(copied.borderWidth, _kBorderWidth);
      expect(copied.backgroundColor, const CoreColor(0xFFFF0000));
    });

    test('merge prefers other style non-null values', () {
      const styleA = CoreChipStyle(borderWidth: _kBorderWidth);
      const styleB = CoreChipStyle(borderColor: CoreColor(0xFF00FF00));
      final merged = styleA.merge(styleB);

      expect(merged.borderWidth, _kBorderWidth);
      expect(merged.borderColor, const CoreColor(0xFF00FF00));
    });

    test('equality works correctly', () {
      const style1 = CoreChipStyle(borderWidth: _kBorderWidth);
      const style2 = CoreChipStyle(borderWidth: _kBorderWidth);
      const style3 = CoreChipStyle(borderWidth: 1);

      expect(style1, equals(style2));
      expect(style1, isNot(equals(style3)));
    });
  });

  group('Chip', () {
    testWidgets('renders child text', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Chip(child: Text('Tag'))),
      );
      await tester.pump();

      expect(find.text('Tag'), findsOneWidget);
    });

    testWidgets('renders with leading widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chip(
            leading: Icon(LucideIcons.info),
            child: Text('With icon'),
          ),
        ),
      );
      await tester.pump();

      expect(_iconFinder(LucideIcons.info), findsOneWidget);
      expect(find.text('With icon'), findsOneWidget);
    });

    testWidgets('renders with trailing widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chip(
            trailing: Icon(LucideIcons.x),
            child: Text('Closable'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Closable'), findsOneWidget);
    });

    testWidgets('invokes onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildApp(
          Chip(
            onTap: () {
              tapped = true;
            },
            child: const Text('Tap me'),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders without onTap', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Chip(child: Text('Static'))),
      );
      await tester.pump();

      expect(find.text('Static'), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = Key('chip-test');

      await tester.pumpWidget(
        _buildApp(const Chip(key: testKey, child: Text('Keyed'))),
      );
      await tester.pump();

      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('Chip with label', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Chip(label: 'Flutter')),
      );
      await tester.pump();

      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('renders with selected state', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Chip(label: 'Selected', selected: true)),
      );
      await tester.pump();

      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('disabled chip does not fire onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildApp(
          Chip(
            onTap: () {
              tapped = true;
            },
            label: 'Disabled',
            enabled: false,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('invokes onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildApp(
          Chip(
            onTap: () {
              tapped = true;
            },
            label: 'Tappable',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Tappable'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders different sizes', (tester) async {
      for (final size in CoreChipSize.values) {
        await tester.pumpWidget(
          _buildApp(Chip(label: 'Size ${size.name}', size: size)),
        );
        await tester.pump();

        expect(find.text('Size ${size.name}'), findsOneWidget);
      }
    });

    testWidgets('renders different colors', (tester) async {
      for (final color in CoreChipColor.values) {
        await tester.pumpWidget(
          _buildApp(Chip(label: 'Color ${color.name}', chipColor: color)),
        );
        await tester.pump();

        expect(find.text('Color ${color.name}'), findsOneWidget);
      }
    });

    testWidgets('renders with onRemove button', (tester) async {
      var removed = false;

      await tester.pumpWidget(
        _buildApp(
          Chip(
            label: 'Removable',
            onRemove: () {
              removed = true;
            },
          ),
        ),
      );
      await tester.pump();

      final removeButton = find.byType(Button);
      expect(removeButton, findsOneWidget);
      await tester.tap(removeButton);
      await tester.pump();

      expect(removed, isTrue);
    });

    testWidgets('renders with leading and trailing', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chip(
            label: 'With icons',
            leading: Icon(LucideIcons.star),
            trailing: Icon(LucideIcons.arrowRight),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('With icons'), findsOneWidget);
      expect(_iconFinder(LucideIcons.star), findsOneWidget);
      expect(_iconFinder(LucideIcons.arrowRight), findsOneWidget);
    });

    testWidgets('applies chipStyle overrides', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Chip(
            label: 'Styled',
            chipStyle: CoreChipStyle(backgroundColor: CoreColor(0xFF0000FF)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Styled'), findsOneWidget);
    });
  });

  group('ChipStyleChain', () {
    test(
      'withStyle merges patch into chipStyle and preserves other fields',
      () {
        var tapped = false;
        final chip = Chip(
          label: 'Flutter',
          chipColor: CoreChipColor.primary,
          selected: true,
          onTap: () => tapped = true,
        );

        final patched = chip.withStyle(
          const CoreChipStyle(borderWidth: 3),
        );

        expect(patched.label, 'Flutter');
        expect(patched.chipColor, CoreChipColor.primary);
        expect(patched.selected, isTrue);
        expect(patched.chipStyle?.borderWidth, 3);
        patched.onTap?.call();
        expect(tapped, isTrue);
      },
    );

    test('later withStyle call wins on conflicting fields', () {
      const chip = Chip(label: 'Flutter');

      final patched = chip
          .withStyle(const CoreChipStyle(borderWidth: 1))
          .withStyle(const CoreChipStyle(borderWidth: 2));

      expect(patched.chipStyle?.borderWidth, 2);
    });

    test('copyWith replaces only the given fields', () {
      final chip = Chip(
        label: 'Flutter',
        chipColor: CoreChipColor.primary,
        selected: true,
        size: CoreChipSize.sm,
        onTap: () {},
      );

      final copied = chip.copyWith(size: CoreChipSize.lg);

      expect(copied.size, CoreChipSize.lg);
      expect(copied.label, chip.label);
      expect(copied.chipColor, chip.chipColor);
      expect(copied.selected, chip.selected);
    });
  });

  // Read from the semantics tree, not from the widget that should have
  // produced it — a `Semantics` that exists but merges away, or sits on
  // a node the reader never reaches, would satisfy a widget lookup and
  // still announce the button as nameless.
  group('remove button — accessible name', () {
    Future<void> pumpChip(
      WidgetTester tester,
      String label, {
      Locale? locale,
    }) async {
      await tester.pumpWidget(
        CoUIApp(
          home: Center(
            child: Chip(label: label, onRemove: () {}),
          ),
          locale: locale,
          supportedLocales: const [Locale('en', 'US'), Locale('ko')],
          theme: ThemeData.fromCore(CoreThemePresets.light),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('names the chip it removes', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpChip(tester, 'Apple');

      final named = find.bySemanticsLabel('Remove Apple');
      expect(named, findsOneWidget);
      expect(
        tester.getSemantics(named),
        isSemantics(label: 'Remove Apple', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('follows the active locale', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpChip(tester, 'Apple', locale: const Locale('ko'));

      expect(find.bySemanticsLabel('Apple 제거'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove Apple'), findsNothing);
      handle.dispose();
    });
  });
}
