import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

void main() {
  group('Status', () {
    testWidgets('renders a status dot', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Status(
            color: CoreStatusColor.success,
            size: CoreStatusSize.md,
            semanticLabel: 'Online',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Status), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(Status),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('animated pulses unless reduced motion is on', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Status(animated: true, semanticLabel: 'Busy')),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(Status),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        material.MaterialApp(
          home: material.Builder(
            builder: (context) {
              return material.MediaQuery(
                data: material.MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: true),
                child: const Theme(
                  data: ThemeData(),
                  child: Status(animated: true),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(Status),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });
  });

  group('StatusStyleChain', () {
    test(
      'withStyle merges patch into statusStyle and preserves other fields',
      () {
        const status = Status(
          color: CoreStatusColor.success,
          size: CoreStatusSize.lg,
          semanticLabel: 'Online',
        );

        final patched = status.withStyle(
          const CoreStatusStyle(borderRadius: CoreBorderRadius.all(4)),
        );

        expect(patched.color, CoreStatusColor.success);
        expect(patched.size, CoreStatusSize.lg);
        expect(patched.semanticLabel, 'Online');
        expect(
          patched.statusStyle?.borderRadius,
          const CoreBorderRadius.all(4),
        );
      },
    );

    test('copyWith replaces only the given fields', () {
      const status = Status(
        color: CoreStatusColor.neutral,
        size: CoreStatusSize.md,
        semanticLabel: 'Offline',
      );

      final copied = status.copyWith(color: CoreStatusColor.error);

      expect(copied.color, CoreStatusColor.error);
      expect(copied.size, CoreStatusSize.md);
      expect(copied.semanticLabel, 'Offline');
      expect(copied.statusStyle, status.statusStyle);
    });

    test('later withStyle call wins on conflicting fields', () {
      const status = Status(color: CoreStatusColor.primary);

      final patched = status
          .withStyle(const CoreStatusStyle(size: 10))
          .withStyle(const CoreStatusStyle(size: 20));

      expect(patched.statusStyle?.size, 20);
    });
  });

  group('Status state', () {
    // The app root gives its child tight constraints; a corner-aligned parent
    // lets the Status take its own size.
    Widget loose(Widget child) =>
        _buildApp(Align(alignment: Alignment.topLeft, child: child));
    const dotKey = ValueKey<String>('dot');
    // The dot: the one Container the Status draws.
    Finder dot() => find.descendant(
      of: find.byType(Status),
      matching: find.byType(Container),
    );
    BoxDecoration decoration(WidgetTester tester) =>
        tester.widget<Container>(dot().first).decoration! as BoxDecoration;

    testWidgets('sizes are 6 · 8 · 10 · 12 · 14', (tester) async {
      for (final entry in {
        CoreStatusSize.xs: 6.0,
        CoreStatusSize.sm: 8.0,
        CoreStatusSize.md: 10.0,
        CoreStatusSize.lg: 12.0,
        CoreStatusSize.xl: 14.0,
      }.entries) {
        await tester.pumpWidget(
          loose(Status(variant: CoreStatusVariant.online, size: entry.key)),
        );
        expect(tester.getSize(dot().first), Size.square(entry.value));
      }
    });

    testWidgets('online is a filled success dot', (tester) async {
      await tester.pumpWidget(
        loose(const Status(variant: CoreStatusVariant.online)),
      );
      final d = decoration(tester);
      expect(d.border, isNull);
      expect(d.color, isNotNull);
    });

    testWidgets('away and offline are 2px rings, not fills', (tester) async {
      for (final state in [CoreStatusVariant.away, CoreStatusVariant.offline]) {
        await tester.pumpWidget(loose(Status(variant: state)));
        final d = decoration(tester);
        expect(d.color, isNull, reason: '$state');
        expect(d.border, isA<Border>());
        expect((d.border! as Border).top.width, 2);
      }
    });

    testWidgets('busy is a filled dot with a 2px bar, 6 long at md', (
      tester,
    ) async {
      await tester.pumpWidget(
        loose(const Status(variant: CoreStatusVariant.busy)),
      );
      expect(decoration(tester).color, isNotNull);
      final bar = find.descendant(
        of: dot().first,
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(bar), const Size(6, 2));
    });

    testWidgets('busy bar length is 4 · 4 · 6 · 8 · 8 by size', (tester) async {
      for (final entry in {
        CoreStatusSize.xs: 4.0,
        CoreStatusSize.sm: 4.0,
        CoreStatusSize.md: 6.0,
        CoreStatusSize.lg: 8.0,
        CoreStatusSize.xl: 8.0,
      }.entries) {
        await tester.pumpWidget(
          loose(Status(variant: CoreStatusVariant.busy, size: entry.key)),
        );
        final bar = find.descendant(
          of: dot().first,
          matching: find.byType(SizedBox),
        );
        expect(
          tester.getSize(bar),
          Size(entry.value, 2),
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('the offline ring is outline, away keeps warning', (
      tester,
    ) async {
      await tester.pumpWidget(
        loose(const Status(variant: CoreStatusVariant.offline)),
      );
      final scheme = Theme.of(tester.element(find.byType(Status))).colorScheme;
      expect(
        (decoration(tester).border! as Border).top.color,
        scheme.resolve(const CoreColor.token(CoreColors.outline)).toValue(),
      );
    });

    testWidgets('label reads on-surface, offline alone on-surface-variant', (
      tester,
    ) async {
      for (final state in CoreStatusVariant.values) {
        await tester.pumpWidget(
          loose(
            Status(
              variant: state,
              label: const Text('x', key: dotKey),
            ),
          ),
        );
        final scheme = Theme.of(
          tester.element(find.byType(Status)),
        ).colorScheme;
        final expected = scheme
            .resolve(
              CoreColor.token(
                state == CoreStatusVariant.offline
                    ? CoreColors.onSurfaceVariant
                    : CoreColors.onSurface,
              ),
            )
            .toValue();
        expect(
          DefaultTextStyle.of(tester.element(find.byKey(dotKey))).style.color,
          expected,
          reason: '$state',
        );
      }
    });

    testWidgets('no state keeps the plain dot with no bar', (tester) async {
      await tester.pumpWidget(
        loose(const Status(color: CoreStatusColor.success)),
      );
      expect(decoration(tester).border, isNull);
      expect(
        find.descendant(of: dot().first, matching: find.byType(SizedBox)),
        findsNothing,
      );
    });

    testWidgets('the label sits beside the dot, gap and role by size', (
      tester,
    ) async {
      const cases = {
        CoreStatusSize.xs: (4.0, 12.0),
        CoreStatusSize.sm: (6.0, 13.0),
        CoreStatusSize.md: (6.0, 14.0),
        CoreStatusSize.lg: (8.0, 15.0),
        CoreStatusSize.xl: (8.0, 15.0),
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(
          loose(
            Status(
              variant: CoreStatusVariant.online,
              size: entry.key,
              label: const Text('Online', key: dotKey),
            ),
          ),
        );
        final dotRect = tester.getRect(dot().first);
        final labelRect = tester.getRect(find.byKey(dotKey));
        expect(labelRect.left - dotRect.right, entry.value.$1);
        expect(
          DefaultTextStyle.of(
            tester.element(find.byKey(dotKey)),
          ).style.fontSize,
          entry.value.$2,
        );
        expect(labelRect.center.dy, closeTo(dotRect.center.dy, 1));
      }
    });

    // The gap beside the label is spacing, so the density moves it a step
    // the way the Web gap (spaceCss) does: md's 6 goes to 4 and 8.
    for (final (density, gap) in [
      (CoreDensity.compact, 4.0),
      (CoreDensity.standard, 6.0),
      (CoreDensity.spacious, 8.0),
    ]) {
      testWidgets('${density.name}: the md label gap is $gap', (tester) async {
        await tester.pumpWidget(
          CoUIApp(
            theme: ThemeData.fromCore(
              CoreThemePresets.previewLight.copyWith(
                textScaling: 1,
                sizeScaling: 1,
                radiusScaling: 1,
              ),
            ),
            density: density,
            home: const Align(
              alignment: Alignment.topLeft,
              child: Status(
                variant: CoreStatusVariant.online,
                label: Text('Online', key: dotKey),
              ),
            ),
          ),
        );
        final dotRect = tester.getRect(dot().first);
        final labelRect = tester.getRect(find.byKey(dotKey));
        expect(labelRect.left - dotRect.right, gap);
      });
    }

    testWidgets('statusStyle ringWidth and bar override the defaults', (
      tester,
    ) async {
      await tester.pumpWidget(
        loose(
          const Status(
            variant: CoreStatusVariant.away,
            statusStyle: CoreStatusStyle(ringWidth: 3),
          ),
        ),
      );
      expect((decoration(tester).border! as Border).top.width, 3);
      await tester.pumpWidget(
        loose(
          const Status(
            variant: CoreStatusVariant.busy,
            statusStyle: CoreStatusStyle(barLength: 4, barWidth: 1),
          ),
        ),
      );
      final bar = find.descendant(
        of: dot().first,
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(bar), const Size(4, 1));
    });
  });
}
