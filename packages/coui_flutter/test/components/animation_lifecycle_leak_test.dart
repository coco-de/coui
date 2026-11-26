// Every `CurvedAnimation` a component creates must be disposed by the time
// the component is gone.
//
// A `CurvedAnimation` registers a status listener on its parent, so one that
// is never disposed pins itself to the controller or route animation it was
// built on. Two shapes kept producing them and neither is visible to a grep
// that only asks "is there a `.dispose()` in this file":
//
//  * rebuilt in `didChangeDependencies` / `build` — each theme change or
//    rebuild allocated a fresh one and dropped the previous one;
//  * built in a free transition function — called every transition frame,
//    with no owner that could ever release it.
//
// The ledger below listens to Flutter's own allocation events (the same
// stream `leak_tracker` reads) and keeps the identities of every
// `CurvedAnimation` created and not yet disposed during a test.
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kScaled = 1.25;
const _kFromOpacityA = 0.2;
const _kFromOpacityB = 0.4;
const _kThemeFlips = 3;
const _kOtherPulse = Duration(milliseconds: CoreDuration.ms1000);

class _CurveLedger {
  final Set<Object> live = Set.identity();
  int created = 0;

  void handleEvent(ObjectEvent event) {
    if (event.object is! CurvedAnimation) return;
    if (event is ObjectCreated) {
      created++;
      live.add(event.object);
    } else if (event is ObjectDisposed) {
      live.remove(event.object);
    }
  }
}

late _CurveLedger _ledger;

ThemeData _theme(int i) => ThemeData(scaling: i.isEven ? 1 : _kScaled);

material.Widget _app(material.Widget child, {int themeIndex = 0}) {
  return material.MaterialApp(
    builder: (context, built) => Theme(data: _theme(themeIndex), child: built!),
    home: material.Scaffold(body: material.Center(child: child)),
  );
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const material.SizedBox());
  await tester.pumpAndSettle();
}

void _expectAllDisposed() {
  expect(
    _ledger.live,
    isEmpty,
    reason:
        '${_ledger.live.length} of ${_ledger.created} CurvedAnimation(s) '
        'outlived the component that created them.',
  );
}

Accordion _accordion() => const Accordion(
  items: [
    AccordionItem(
      content: material.Text('content'),
      trigger: AccordionTrigger(child: material.Text('trigger')),
    ),
  ],
);

Collapsible _collapsible() => const Collapsible(
  trigger: material.Text('trigger'),
  content: material.Text('content'),
);

material.Widget _opener({
  required void Function(material.BuildContext) onOpen,
}) {
  return material.Builder(
    builder: (context) => material.GestureDetector(
      onTap: () => onOpen(context),
      child: const material.Text('open'),
    ),
  );
}

void main() {
  setUp(() {
    _ledger = _CurveLedger();
    FlutterMemoryAllocations.instance.addListener(_ledger.handleEvent);
  });

  tearDown(() {
    FlutterMemoryAllocations.instance.removeListener(_ledger.handleEvent);
  });

  // Without this the suite would pass on a build where allocation events
  // are compiled out — every ledger would simply stay empty.
  test('the ledger sees CurvedAnimation allocations', () {
    expect(kFlutterMemoryAllocationsEnabled, isTrue);
    final parent = AnimationController(vsync: const TestVSync());
    final curve = CurvedAnimation(parent: parent, curve: material.Curves.ease);
    expect(_ledger.live, contains(curve));
    curve.dispose();
    parent.dispose();
    expect(_ledger.live, isEmpty);
  });

  testWidgets('Accordion — theme changes and toggling leave nothing behind', (
    tester,
  ) async {
    for (var i = 0; i < _kThemeFlips; i++) {
      await tester.pumpWidget(_app(_accordion(), themeIndex: i));
    }
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    await _unmount(tester);

    _expectAllDisposed();
  });

  testWidgets('Collapsible — theme changes and toggling leave nothing behind', (
    tester,
  ) async {
    for (var i = 0; i < _kThemeFlips; i++) {
      await tester.pumpWidget(_app(_collapsible(), themeIndex: i));
    }
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    await _unmount(tester);

    _expectAllDisposed();
  });

  testWidgets('Skeleton — re-resolving the pulse leaves nothing behind', (
    tester,
  ) async {
    final styles = [
      const CoreSkeletonStyle(fromOpacity: _kFromOpacityA),
      const CoreSkeletonStyle(fromOpacity: _kFromOpacityB),
      // A new period restarts the pulse on the same controller.
      const CoreSkeletonStyle(duration: _kOtherPulse),
    ];
    for (final style in styles) {
      await tester.pumpWidget(
        _app(Skeleton(height: 20, width: 40, skeletonStyle: style)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _unmount(tester);

    _expectAllDisposed();
  });

  testWidgets('Swap — toggling leaves nothing behind', (tester) async {
    for (final checked in [false, true, false]) {
      await tester.pumpWidget(
        _app(
          Swap(
            animation: .rotate,
            checked: checked,
            offContent: const material.Text('off'),
            onContent: const material.Text('on'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
    await _unmount(tester);

    _expectAllDisposed();
  });

  for (final transformBackdrop in [false, true]) {
    testWidgets(
      'Drawer (transformBackdrop: $transformBackdrop) — open, rebuild, close '
      'leaves nothing behind',
      (tester) async {
        await tester.pumpWidget(
          material.MaterialApp(
            builder: (context, built) => Theme(
              data: const ThemeData(),
              child: DrawerBackdropLayer(child: built!),
            ),
            home: material.Center(
              child: _opener(
                onOpen: (context) => unawaited(
                  openDrawer<void>(
                    context: context,
                    side: .left,
                    transformBackdrop: transformBackdrop,
                    builder: (context) =>
                        const Drawer(content: material.Text('panel')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('panel'), findsOneWidget);

        tester
            .state<material.NavigatorState>(
              find.byType(material.Navigator).first,
            )
            .pop();
        await tester.pumpAndSettle();
        await _unmount(tester);

        // The route still eases its slide — the ledger must have seen it.
        expect(_ledger.created, greaterThan(0));
        _expectAllDisposed();
      },
    );
  }

  testWidgets('Dialog — open and close leave nothing behind', (tester) async {
    await tester.pumpWidget(
      _app(
        _opener(
          onOpen: (context) => unawaited(
            showDialog<void>(
              context: context,
              builder: (_) =>
                  const Dialog(content: material.Text('dialog content')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Frame-by-frame: the old transition built its curves per frame.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(find.text('dialog content'), findsOneWidget);

    tester
        .state<material.NavigatorState>(find.byType(material.Navigator).first)
        .pop();
    await tester.pumpAndSettle();
    await _unmount(tester);

    // The route and its transition still build curves — a ledger that saw
    // none would be proving nothing.
    expect(_ledger.created, greaterThan(0));
    _expectAllDisposed();
  });
}
