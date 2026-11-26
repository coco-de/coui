import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// The token size each layout mode states for its glyph.
const Map<CoreNavigationBarMode, double> _tokenSize = {
  CoreNavigationBarMode.bar: 24.0,
  CoreNavigationBarMode.rail: 24.0,
  CoreNavigationBarMode.sidebar: 20.0,
};

Widget _bar(CoreNavigationBarMode mode, {double width = 360}) {
  return SizedBox(
    width: width,
    height: 400,
    child: NavigationBar(
      mode: mode,
      labelMode: CoreNavigationLabelMode.all,
      selectedIndex: 0,
      onSelected: (_) {},
      items: const [
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.inbox, key: ValueKey('icon-0')),
          label: 'Inbox',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.search),
          label: 'Search',
        ),
      ],
    ),
  );
}

void main() {
  group('the destination icon is scaled once', () {
    for (final scaling in [1.0, 1.25, 1.5]) {
      for (final mode in CoreNavigationBarMode.values) {
        testWidgets('${mode.name} at scaling $scaling', (tester) async {
          await pumpTestApp(
            tester,
            _bar(mode),
            theme: ThemeData(scaling: scaling),
          );
          await tester.pump();

          // The glyph's box is the token size times the theme scaling —
          // the `Icon` scales its own box, so the size handed to it
          // through the ambient `IconTheme` is the token size as stated.
          expect(
            tester.getSize(find.byKey(const ValueKey('icon-0'))).width,
            closeTo(_tokenSize[mode]! * scaling, 0.01),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('the resolver states the icon at both extents', () {
    for (final mode in CoreNavigationBarMode.values) {
      testWidgets('${mode.name} at scaling 1.25', (tester) async {
        late ResolvedNavigationBar resolved;
        await pumpTestApp(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveNavigationBar(
                context,
                mode: mode,
                variant: CoreNavigationBarVariant.defaultVariant,
              );
              return const SizedBox.shrink();
            },
          ),
          theme: const ThemeData(scaling: 1.25),
        );

        // The token size is what the `Icon` is handed; the box is what
        // lands on screen and what the width estimates have to count.
        expect(resolved.iconSize, _tokenSize[mode]);
        expect(resolved.iconBoxSize, closeTo(_tokenSize[mode]! * 1.25, 0.01));
      });
    }
  });

  group('the fill-or-scroll decision counts the scaled glyph', () {
    // Three icon-only destinations at scaling 1.25: each is its padding
    // (5 + 5), the icon box's inset (15 + 15) and a 30 px glyph, 70 wide and
    // 210 in all; the bar's own side padding (12 × 1.25 = 15, twice) comes
    // off the width it is given. An estimate that counts the unscaled 24 px
    // glyph reads 204.
    const barPadding = 30.0;
    Widget bar(double availableWidth) {
      return SizedBox(
        width: availableWidth + barPadding,
        child: NavigationBar(
          labelMode: CoreNavigationLabelMode.none,
          selectedIndex: 0,
          onSelected: (_) {},
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.inbox),
              label: 'Inbox',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.search),
              label: 'Search',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.settings),
              label: 'Settings',
            ),
          ],
        ),
      );
    }

    testWidgets('an icon-only bar that no longer fits scrolls', (
      tester,
    ) async {
      // Room for the row the unscaled glyph reads, not for the real one —
      // then each equal share (68) is narrower than its own content (70).
      await pumpTestApp(
        tester,
        bar(205),
        theme: const ThemeData(scaling: 1.25),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('an icon-only bar that fits fills', (tester) async {
      await pumpTestApp(
        tester,
        bar(211),
        theme: const ThemeData(scaling: 1.25),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });
}
