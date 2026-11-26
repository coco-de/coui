import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  const selectionKey = ValueKey('coui-navigation-selection');
  const lensKey = ValueKey('coui-navigation-lens');
  const items = [
    CoreNavigationBarItem<Widget>.destination(label: 'Home'),
    CoreNavigationBarItem<Widget>.destination(label: 'Search'),
    CoreNavigationBarItem<Widget>.destination(label: 'Library'),
  ];

  for (final direction in TextDirection.values) {
    for (final reducedMotion in [false, true]) {
      testWidgets(
        'scrubbing tracks continuously and commits once: '
        '$direction reduced=$reducedMotion',
        (tester) async {
          var selected = 0;
          final commits = <int>[];
          await pumpTestApp(
            tester,
            StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 360,
                child: NavigationBar(
                  items: items,
                  labelMode: .all,
                  selectedIndex: selected,
                  navigationBarStyle: const CoreNavigationBarStyle(
                    surfaceStyle: .liquidGlass,
                  ),
                  onSelected: (index) {
                    commits.add(index);
                    setState(() => selected = index);
                  },
                ),
              ),
            ),
            textDirection: direction,
            disableAnimations: reducedMotion,
          );
          final pill = find.byKey(selectionKey);
          final start = tester.getCenter(find.text('Home'));
          final end = tester.getCenter(find.text('Library'));
          final restingSize = tester.getSize(pill);
          final gesture = await tester.startGesture(start);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 180));
          expect(
            tester.getSize(pill).height,
            reducedMotion
                ? restingSize.height
                : greaterThan(restingSize.height),
          );
          await gesture.moveTo(Offset.lerp(start, end, .35)!);
          await tester.pump();
          await _pumpFrames(tester, 5);
          final firstPosition = tester.getCenter(pill).dx;
          await gesture.moveTo(Offset.lerp(start, end, .4)!);
          await tester.pump();
          await _pumpFrames(tester, 5);
          final secondPosition = tester.getCenter(pill).dx;
          expect(
            direction == .ltr
                ? secondPosition > firstPosition
                : secondPosition < firstPosition,
            isTrue,
          );
          expect(commits, isEmpty);
          expect(selected, 0);
          expect(find.byType(BackdropFilter), findsOneWidget);
          await gesture.moveTo(end);
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
          expect(commits, [2]);
          expect(tester.getCenter(pill).dx, closeTo(end.dx, .1));
          expect(tester.hasRunningAnimations, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'bubble responds to speed then relaxes: reduced=$reducedMotion',
      (
        tester,
      ) async {
        final commits = <int>[];
        await pumpTestApp(
          tester,
          SizedBox(
            width: 360,
            child: NavigationBar(
              items: items,
              labelMode: .all,
              selectedIndex: 0,
              onSelected: commits.add,
              navigationBarStyle: const CoreNavigationBarStyle(
                surfaceStyle: .liquidGlass,
              ),
            ),
          ),
          disableAnimations: reducedMotion,
        );
        Size size() => tester.getSize(find.byKey(selectionKey));
        final resting = size();
        final home = tester.getCenter(find.text('Home'));
        final gesture = await tester.startGesture(home);
        await tester.pumpAndSettle();
        final pressed = size();
        await gesture.moveTo(
          home + const Offset(25, 0),
          timeStamp: const Duration(milliseconds: 200),
        );
        await tester.pump();
        await _pumpFrames(tester, 5);
        final slow = size();
        await gesture.moveTo(
          home + const Offset(120, 0),
          timeStamp: const Duration(milliseconds: 280),
        );
        await tester.pump();
        await _pumpFrames(tester, 5);
        final fast = size();
        if (reducedMotion) {
          expect([pressed, slow, fast], everyElement(resting));
          expect(tester.hasRunningAnimations, isFalse);
          expect(find.byKey(lensKey), findsNothing);
        } else {
          expect(slow.height, greaterThan(pressed.height));
          expect(fast.height, greaterThan(slow.height));
          expect(fast.width, lessThan(slow.width));
        }
        // Reversing travel stays finite; stopping restores the held geometry.
        await gesture.moveTo(
          home + const Offset(45, 0),
          timeStamp: const Duration(milliseconds: 360),
        );
        await tester.pump();
        await _pumpFrames(tester, 5);
        expect(size().width.isFinite && size().height.isFinite, isTrue);
        expect(size().width, greaterThan(0));
        await tester.pumpAndSettle();
        expect(size().width, closeTo(pressed.width, .1));
        expect(size().height, closeTo(pressed.height, .1));
        expect(commits, isEmpty);
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(size(), resting);
        expect(find.byKey(lensKey), findsNothing);
        expect(
          find.byKey(const ValueKey('coui-navigation-optical-lens')),
          findsNothing,
        );
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('the same timed drag has comparable motion at 60 and 120 Hz', (
    tester,
  ) async {
    Future<List<(double, Size)>> trace(int framesPerSegment) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpTestApp(
        tester,
        SizedBox(
          width: 360,
          child: NavigationBar(
            items: items,
            labelMode: .all,
            selectedIndex: 0,
            onSelected: (_) {},
            navigationBarStyle: const CoreNavigationBarStyle(
              surfaceStyle: .liquidGlass,
            ),
          ),
        ),
      );
      final home = tester.getCenter(find.text('Home'));
      final end = tester.getCenter(find.text('Library'));
      final gesture = await tester.startGesture(home);
      await tester.pumpAndSettle();
      final samples = <(double, Size)>[];
      // Each segment lasts 200 ms: accelerate right, reverse, then pause.
      final points = [home, Offset.lerp(home, end, .8)!, home, home];
      var elapsedMicros = 0;
      for (var segment = 0; segment < points.length - 1; segment++) {
        var segmentMicros = 0;
        for (var frame = 1; frame <= framesPerSegment; frame++) {
          final nextMicros = (200000 * frame / framesPerSegment).round();
          final deltaMicros = nextMicros - segmentMicros;
          segmentMicros = nextMicros;
          elapsedMicros += deltaMicros;
          await gesture.moveTo(
            Offset.lerp(
              points[segment],
              points[segment + 1],
              frame / framesPerSegment,
            )!,
            timeStamp: Duration(microseconds: elapsedMicros),
          );
          await tester.pump(Duration(microseconds: deltaMicros));
          if (frame == framesPerSegment ~/ 2 || frame == framesPerSegment) {
            samples.add((
              tester.getCenter(find.byKey(selectionKey)).dx - home.dx,
              tester.getSize(find.byKey(selectionKey)),
            ));
          }
        }
      }
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      return samples;
    }

    final at60 = await trace(12);
    final at120 = await trace(24);
    expect(at60.length, at120.length);
    for (var index = 0; index < at60.length; index++) {
      // A display frame samples a different point on the same pointer path.
      // Allow a few logical pixels, but no frame-rate-dependent motion change.
      expect(at60[index].$1, closeTo(at120[index].$1, 6));
      expect(at60[index].$2.width, closeTo(at120[index].$2.width, 2));
      expect(at60[index].$2.height, closeTo(at120[index].$2.height, 2));
    }
    expect(tester.takeException(), isNull);
  });

  for (final releaseBeforeToggle in [false, true]) {
    testWidgets(
      'enabling reduced motion stops an active lens: '
      'released=$releaseBeforeToggle',
      (tester) async {
        var reduced = false;
        late StateSetter update;
        await pumpTestApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
                child: SizedBox(
                  width: 360,
                  child: NavigationBar(
                    items: items,
                    labelMode: .all,
                    selectedIndex: 0,
                    onSelected: (_) {},
                    navigationBarStyle: const CoreNavigationBarStyle(
                      surfaceStyle: .liquidGlass,
                    ),
                  ),
                ),
              );
            },
          ),
        );
        final home = tester.getCenter(find.text('Home'));
        final restSize = tester.getSize(find.byKey(selectionKey));
        final gesture = await tester.startGesture(home);
        await tester.pumpAndSettle();
        await gesture.moveTo(tester.getCenter(find.text('Library')));
        await tester.pump();
        await _pumpFrames(tester, 3);
        if (releaseBeforeToggle) {
          await gesture.up();
          await tester.pump();
        }
        expect(find.byKey(lensKey), findsOneWidget);
        expect(tester.hasRunningAnimations, isTrue);
        update(() => reduced = true);
        await tester.pump();
        expect(find.byKey(lensKey), findsNothing);
        expect(tester.getSize(find.byKey(selectionKey)), restSize);
        // Allow a frame for descendants to apply the ambient preference.
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.hasRunningAnimations, isFalse);
        if (!releaseBeforeToggle) {
          // Re-enabling motion while held resumes the same material clock.
          update(() => reduced = false);
          await tester.pump();
          await _pumpFrames(tester, 8);
          expect(find.byKey(lensKey), findsOneWidget);
          update(() => reduced = true);
          await tester.pump();
          expect(find.byKey(lensKey), findsNothing);
          await gesture.cancel();
        }
        await tester.pump();
        expect(
          tester.getCenter(find.byKey(selectionKey)).dx,
          closeTo(home.dx, .1),
        );
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('release keeps the lens visible until the selection settles', (
    tester,
  ) async {
    var selected = 0;
    final commits = <int>[];
    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 360,
          child: NavigationBar(
            items: items,
            labelMode: .all,
            selectedIndex: selected,
            navigationBarStyle: const CoreNavigationBarStyle(
              surfaceStyle: .liquidGlass,
            ),
            onSelected: (index) {
              commits.add(index);
              setState(() => selected = index);
            },
          ),
        ),
      ),
    );
    final home = tester.getCenter(find.text('Home'));
    final end = tester.getCenter(find.text('Library'));
    final gesture = await tester.startGesture(home);
    await tester.pumpAndSettle();
    await gesture.moveTo(end);
    await tester.pump();
    await _pumpFrames(tester, 3);
    await gesture.up();
    await tester.pump();
    expect(commits, [2]);
    expect(find.byKey(lensKey), findsOneWidget);
    final released = tester.getCenter(find.byKey(selectionKey)).dx;
    expect((released - end.dx).abs(), greaterThan(1));
    await _pumpFrames(tester, 3);
    expect(find.byKey(lensKey), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(selectionKey)).dx,
      greaterThan(released),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(lensKey), findsNothing);
    expect(tester.getCenter(find.byKey(selectionKey)).dx, closeTo(end.dx, .1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('declined selection returns the lens to the host selection', (
    tester,
  ) async {
    final commits = <int>[];
    await pumpTestApp(
      tester,
      SizedBox(
        width: 360,
        child: NavigationBar(
          items: items,
          labelMode: .all,
          selectedIndex: 0,
          onSelected: commits.add,
          navigationBarStyle: const CoreNavigationBarStyle(
            surfaceStyle: .liquidGlass,
          ),
        ),
      ),
    );
    final home = tester.getCenter(find.text('Home'));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(tester.getCenter(find.text('Library')));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pump();
    expect(commits, [2]);
    expect(find.byKey(lensKey), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byKey(selectionKey)).dx, closeTo(home.dx, .1));
    expect(find.byKey(lensKey), findsNothing);
  });

  for (final direction in TextDirection.values) {
    testWidgets('edge resistance is smooth and bounded: $direction', (
      tester,
    ) async {
      final commits = <int>[];
      await pumpTestApp(
        tester,
        SizedBox(
          width: 360,
          child: NavigationBar(
            items: items,
            labelMode: .all,
            selectedIndex: 0,
            onSelected: commits.add,
            navigationBarStyle: const CoreNavigationBarStyle(
              surfaceStyle: .liquidGlass,
            ),
          ),
        ),
        textDirection: direction,
      );
      final home = tester.getCenter(find.text('Home'));
      final cell = (tester.getCenter(find.text('Search')).dx - home.dx).abs();
      final outward = direction == .ltr ? -1.0 : 1.0;
      final gesture = await tester.startGesture(home);
      await gesture.moveTo(home + Offset(outward * cell, 0));
      await tester.pumpAndSettle();
      final near = (tester.getCenter(find.byKey(selectionKey)).dx - home.dx)
          .abs();
      await gesture.moveTo(home + Offset(outward * cell * 10, 0));
      await tester.pumpAndSettle();
      final far = (tester.getCenter(find.byKey(selectionKey)).dx - home.dx)
          .abs();
      expect(near, greaterThan(0));
      expect(far, greaterThan(near));
      expect(far, lessThan(cell / 2));
      expect(far - near, lessThan(near));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(
        tester.getCenter(find.byKey(selectionKey)).dx,
        closeTo(home.dx, .1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reversal and re-grabbing preserve the rendered position', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      SizedBox(
        width: 360,
        child: NavigationBar(
          items: items,
          labelMode: .all,
          selectedIndex: 0,
          onSelected: (_) {},
          navigationBarStyle: const CoreNavigationBarStyle(
            surfaceStyle: .liquidGlass,
          ),
        ),
      ),
    );
    double position() => tester.getCenter(find.byKey(selectionKey)).dx;
    final home = tester.getCenter(find.text('Home'));
    final end = tester.getCenter(find.text('Library'));
    var gesture = await tester.startGesture(home);
    await tester.pumpAndSettle();
    await gesture.moveTo(end);
    await tester.pump();
    await _pumpFrames(tester, 4);
    final beforeReversal = position();
    await gesture.moveTo(home);
    await tester.pump();
    expect(position(), closeTo(beforeReversal, .01));
    await tester.pump(const Duration(milliseconds: 1));
    // Velocity cannot jump to the reversed target's direction immediately.
    expect(position(), greaterThan(beforeReversal));
    await _pumpFrames(tester, 2);
    await gesture.cancel();
    await tester.pump();
    final beforeRegrab = position();
    gesture = await tester.startGesture(Offset(beforeRegrab, home.dy));
    await tester.pump();
    expect(position(), closeTo(beforeRegrab, .01));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(position(), closeTo(home.dx, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel and release over a disabled item restore the controlled selection',
    (tester) async {
      final commits = <int>[];
      await pumpTestApp(
        tester,
        SizedBox(
          width: 360,
          child: NavigationBar(
            items: const [
              CoreNavigationBarItem.destination(label: 'Home'),
              CoreNavigationBarItem.destination(
                label: 'Disabled',
                enabled: false,
              ),
              CoreNavigationBarItem.destination(label: 'Library'),
            ],
            labelMode: .all,
            selectedIndex: 0,
            onSelected: commits.add,
            navigationBarStyle: const CoreNavigationBarStyle(
              surfaceStyle: .liquidGlass,
            ),
          ),
        ),
      );
      final home = tester.getCenter(find.text('Home'));
      var gesture = await tester.startGesture(home);
      await gesture.moveTo(tester.getCenter(find.text('Library')));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(
        tester.getCenter(find.byKey(selectionKey)).dx,
        closeTo(home.dx, .1),
      );
      gesture = await tester.startGesture(home);
      await gesture.moveTo(tester.getCenter(find.text('Disabled')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(
        tester.getCenter(find.byKey(selectionKey)).dx,
        closeTo(home.dx, .1),
      );
    },
  );

  testWidgets(
    'external selection and item removal cancel an in-flight drag safely',
    (tester) async {
      final commits = <int>[];
      var selected = 0;
      var visibleItems = items;
      late StateSetter update;
      await pumpTestApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SizedBox(
              width: 360,
              child: NavigationBar(
                items: visibleItems,
                selectedIndex: selected,
                labelMode: .all,
                onSelected: commits.add,
                navigationBarStyle: const CoreNavigationBarStyle(
                  surfaceStyle: .liquidGlass,
                ),
              ),
            );
          },
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Home')),
      );
      await gesture.moveTo(tester.getCenter(find.text('Library')));
      await tester.pump();
      update(() {
        selected = 1;
        visibleItems = items.take(2).toList();
      });
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(
        tester.getCenter(find.byKey(selectionKey)).dx,
        closeTo(tester.getCenter(find.text('Search')).dx, .1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('secondary mouse drag never previews or selects a destination', (
    tester,
  ) async {
    final commits = <int>[];
    await pumpTestApp(
      tester,
      SizedBox(
        width: 360,
        child: NavigationBar(
          items: items,
          labelMode: .all,
          selectedIndex: 0,
          onSelected: commits.add,
          navigationBarStyle: const CoreNavigationBarStyle(
            surfaceStyle: .liquidGlass,
          ),
        ),
      ),
    );
    final home = tester.getCenter(find.text('Home'));
    final gesture = await tester.startGesture(
      home,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.moveTo(tester.getCenter(find.text('Library')));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commits, isEmpty);
    expect(tester.getCenter(find.byKey(selectionKey)).dx, closeTo(home.dx, .1));
  });
}

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
