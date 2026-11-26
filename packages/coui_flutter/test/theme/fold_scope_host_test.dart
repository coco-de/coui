// The fold of a platform that does not report it to Flutter: what
// `FoldReading` makes of the plugin's measurement, how `FoldScopeHost` writes
// it into `MediaQuery.displayFeatures`, and that the rest of the kit then
// reads an iPhone's fold the way it reads Android's — `FoldScope.of` and the
// segment a dialog opens in.
//
// The geometry is the folding iPhone's inner screen as its simulator reports
// it: 951 × 669 logical pixels held wide, with the system's division 40 wide
// across the middle (455.5 to 495.5).
import 'dart:async';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

const Size _wide = Size(951, 669);
const Size _tall = Size(669, 951);

const Rect _divisionWide = Rect.fromLTWH(455.5, 0, 40, 669);
const Rect _divisionTall = Rect.fromLTWH(0, 455.5, 669, 40);

const w.Key _content = w.ValueKey('content');

FoldReading _reading(
  FoldHingeStatus status, {
  Rect bounds = _divisionWide,
  bool active = false,
}) => FoldReading(
  status: status,
  divisions: [FoldDivision(bounds: bounds, active: active)],
);

Map<String, Object?> _message(
  String status, {
  Rect bounds = _divisionWide,
  bool active = false,
}) => {
  'status': status,
  'divisions': [
    {
      'left': bounds.left,
      'top': bounds.top,
      'width': bounds.width,
      'height': bounds.height,
      'active': active,
    },
  ],
};

/// A feed a test drives: it says what the device reports.
class _TestFeed extends FoldFeed {
  final _watchers = <ValueChanged<FoldReading>>[];
  FoldReading _current = FoldReading.none;
  int refreshes = 0;

  int get watchers => _watchers.length;

  void report(FoldReading reading) {
    _current = reading;
    for (final watcher in List.of(_watchers)) {
      watcher(reading);
    }
  }

  @override
  VoidCallback watch(ValueChanged<FoldReading> onReading) {
    _watchers.add(onReading);
    onReading(_current);

    return () => _watchers.remove(onReading);
  }

  @override
  void refresh() => refreshes += 1;
}

void _showViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Counts its builds and keeps a number, to tell a rebuild from a remount.
class _Probe extends w.StatefulWidget {
  const _Probe({required this.onBuild});

  final void Function(w.BuildContext context, int mounts) onBuild;

  @override
  w.State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends w.State<_Probe> {
  static int _mounted = 0;
  late final int _mount;

  @override
  void initState() {
    super.initState();
    _mount = _mounted += 1;
  }

  @override
  w.Widget build(w.BuildContext context) {
    widget.onBuild(context, _mount);

    return const w.SizedBox.shrink();
  }
}

void main() {
  group('FoldReading makes display features of what the plugin measured', () {
    test('no hinge, or folded shut, is no fold', () {
      for (final status in [
        FoldHingeStatus.unavailable,
        FoldHingeStatus.closed,
      ]) {
        expect(
          _reading(status, active: true).displayFeaturesFor(_wide),
          isEmpty,
          reason: status.name,
        );
      }
    });

    test('partly open with the division active is a fold as wide as the '
        'strip, half opened', () {
      final features = _reading(
        FoldHingeStatus.partiallyOpen,
        active: true,
      ).displayFeaturesFor(_wide);

      expect(features, const [
        ui.DisplayFeature(
          bounds: _divisionWide,
          type: ui.DisplayFeatureType.fold,
          state: ui.DisplayFeatureState.postureHalfOpened,
        ),
      ]);
    });

    test('lying flat is a line where the strip is centred, flat', () {
      final features = _reading(
        FoldHingeStatus.fullyOpen,
      ).displayFeaturesFor(_wide);

      expect(features, const [
        ui.DisplayFeature(
          bounds: Rect.fromLTWH(475.5, 0, 0, 669),
          type: ui.DisplayFeatureType.fold,
          state: ui.DisplayFeatureState.postureFlat,
        ),
      ]);
    });

    test('the hinge decides, not a division still marked active just after '
        'the device is laid flat', () {
      final features = _reading(
        FoldHingeStatus.fullyOpen,
        active: true,
      ).displayFeaturesFor(_wide);

      expect(features.single.bounds.width, 0);
      expect(features.single.state, ui.DisplayFeatureState.postureFlat);
    });

    test('partly open before the division turns active, or a hinge that does '
        'not say, splits nothing and names no posture', () {
      for (final status in [
        FoldHingeStatus.partiallyOpen,
        FoldHingeStatus.unknown,
      ]) {
        final features = _reading(status).displayFeaturesFor(_wide);

        expect(features.single.bounds.width, 0, reason: status.name);
        expect(
          features.single.state,
          ui.DisplayFeatureState.unknown,
          reason: status.name,
        );
      }
    });

    test('held tall, the fold runs across', () {
      final features = _reading(
        FoldHingeStatus.partiallyOpen,
        bounds: _divisionTall,
        active: true,
      ).displayFeaturesFor(_tall);

      expect(features.single.bounds, _divisionTall);
      expect(
        _reading(
          FoldHingeStatus.fullyOpen,
          bounds: _divisionTall,
        ).displayFeaturesFor(_tall).single.bounds,
        const Rect.fromLTWH(0, 475.5, 669, 0),
      );
    });

    test('a division the window only reaches the edge of is left out', () {
      // Two apps side by side meet at the fold: the left one is 455.5 wide
      // and the strip starts where it ends.
      const half = Size(455.5, 669);

      expect(
        _reading(
          FoldHingeStatus.partiallyOpen,
          active: true,
        ).displayFeaturesFor(half),
        isEmpty,
      );
      expect(
        _reading(
          FoldHingeStatus.partiallyOpen,
          bounds: const Rect.fromLTWH(-20, 0, 40, 669),
          active: true,
        ).displayFeaturesFor(half),
        isEmpty,
      );
    });

    test('a division that does not run across the viewport is left out', () {
      expect(
        _reading(
          FoldHingeStatus.partiallyOpen,
          bounds: const Rect.fromLTWH(455.5, 100, 40, 300),
          active: true,
        ).displayFeaturesFor(_wide),
        isEmpty,
      );
      expect(
        _reading(
          FoldHingeStatus.partiallyOpen,
          bounds: Rect.zero,
          active: true,
        ).displayFeaturesFor(_wide),
        isEmpty,
      );
    });

    test('a frame a fraction of a point short of the edges still crosses', () {
      final features = _reading(
        FoldHingeStatus.partiallyOpen,
        bounds: const Rect.fromLTWH(455.5, 0.3, 40, 668.4),
        active: true,
      ).displayFeaturesFor(_wide);

      expect(features.single.bounds, _divisionWide);
    });
  });

  group('FoldReading reads what the plugin sent', () {
    test('a reading in the expected shape', () {
      expect(
        FoldReading.fromMessage(_message('partiallyOpen', active: true)),
        _reading(FoldHingeStatus.partiallyOpen, active: true),
      );
      expect(
        FoldReading.fromMessage(const {
          'status': 'unavailable',
          'divisions': <Object?>[],
        }),
        FoldReading.none,
      );
    });

    test('anything else is no fold', () {
      final strip = (_message('fullyOpen')['divisions']! as List).single as Map;
      for (final message in <Object?>[
        null,
        'fullyOpen',
        const <Object?, Object?>{},
        const {'status': 'fullyOpen'},
        const {'status': 'ajar', 'divisions': <Object?>[]},
        const {'status': 3, 'divisions': <Object?>[]},
        const {'status': 'fullyOpen', 'divisions': 'none'},
        const {
          'status': 'fullyOpen',
          'divisions': ['strip'],
        },
        {
          'status': 'fullyOpen',
          'divisions': [
            {...strip, 'width': -1.0},
          ],
        },
        {
          'status': 'fullyOpen',
          'divisions': [
            {...strip, 'active': 'yes'},
          ],
        },
        {
          'status': 'fullyOpen',
          'divisions': [
            {...strip}..remove('top'),
          ],
        },
      ]) {
        expect(
          FoldReading.fromMessage(message),
          FoldReading.none,
          reason: '$message',
        );
      }
    });
  });

  group('FoldScopeHost writes the fold where the kit reads it', () {
    testWidgets('FoldScope.of reads a folding iPhone as it reads the rest', (
      tester,
    ) async {
      _showViewport(tester, _wide);
      final feed = _TestFeed()..report(_reading(FoldHingeStatus.fullyOpen));
      final seen = <CoreFoldLayout>[];
      await tester.pumpWidget(
        FoldScopeHost(
          feed: feed,
          child: w.Builder(
            builder: (context) {
              seen.add(FoldScope.of(context));

              return const w.SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen.last.kind, CoreFoldableKind.fold);
      expect(seen.last.posture, CoreFoldPosture.flat);
      expect(seen.last.isSplit, isFalse);

      feed.report(_reading(FoldHingeStatus.partiallyOpen, active: true));
      await tester.pump();

      expect(seen.last.kind, CoreFoldableKind.fold);
      expect(seen.last.posture, CoreFoldPosture.book);
      expect(seen.last.segments, const [
        CoreViewportRect(left: 0, top: 0, width: 455.5, height: 669),
        CoreViewportRect(left: 495.5, top: 0, width: 455.5, height: 669),
      ]);

      feed.report(_reading(FoldHingeStatus.closed));
      await tester.pump();

      expect(seen.last.folds, isEmpty);
      expect(seen.last.kind, isNull);
    });

    testWidgets('held tall and partly open it stands like a laptop', (
      tester,
    ) async {
      _showViewport(tester, _tall);
      final feed = _TestFeed()
        ..report(
          _reading(
            FoldHingeStatus.partiallyOpen,
            bounds: _divisionTall,
            active: true,
          ),
        );
      late CoreFoldLayout layout;
      await tester.pumpWidget(
        FoldScopeHost(
          feed: feed,
          child: w.Builder(
            builder: (context) {
              layout = FoldScope.of(context);

              return const w.SizedBox.shrink();
            },
          ),
        ),
      );

      expect(layout.posture, CoreFoldPosture.tabletop);
      expect(layout.segments, const [
        CoreViewportRect(left: 0, top: 0, width: 669, height: 455.5),
        CoreViewportRect(left: 0, top: 495.5, width: 669, height: 455.5),
      ]);
    });

    testWidgets('folding rebuilds what reads the fold and remounts nothing', (
      tester,
    ) async {
      _showViewport(tester, _wide);
      final feed = _TestFeed()..report(_reading(FoldHingeStatus.closed));
      final mounts = <int>{};
      var builds = 0;
      await tester.pumpWidget(
        FoldScopeHost(
          feed: feed,
          child: _Probe(
            onBuild: (context, mount) {
              FoldScope.of(context);
              mounts.add(mount);
              builds += 1;
            },
          ),
        ),
      );
      final afterMount = builds;

      // Shut to open flat to partly open and back: a fold appears, splits
      // and goes.
      for (final reading in [
        _reading(FoldHingeStatus.fullyOpen),
        _reading(FoldHingeStatus.partiallyOpen, active: true),
        _reading(FoldHingeStatus.closed),
      ]) {
        feed.report(reading);
        await tester.pump();
      }

      expect(builds, afterMount + 3);
      expect(mounts, hasLength(1));
    });

    testWidgets('an unchanged fold hands back the same list', (tester) async {
      _showViewport(tester, _wide);
      final feed = _TestFeed()
        ..report(_reading(FoldHingeStatus.partiallyOpen, active: true));
      var builds = 0;
      final child = w.Builder(
        builder: (context) {
          w.MediaQuery.displayFeaturesOf(context);
          builds += 1;

          return const w.SizedBox.shrink();
        },
      );
      w.Widget under(w.EdgeInsets padding) => w.MediaQuery(
        data: w.MediaQueryData(size: _wide, padding: padding),
        child: FoldScopeHost(feed: feed, child: child),
      );
      await tester.pumpWidget(under(w.EdgeInsets.zero));
      // The host is rebuilt for something that is not the fold, and the
      // device reports the reading it already reported.
      await tester.pumpWidget(under(const w.EdgeInsets.only(right: 84)));
      feed.report(_reading(FoldHingeStatus.partiallyOpen, active: true));
      await tester.pump();

      expect(builds, 1);
    });

    testWidgets('stands down where a fold is already reported', (tester) async {
      _showViewport(tester, _wide);
      const reported = ui.DisplayFeature(
        bounds: Rect.fromLTWH(475.5, 0, 0, 669),
        type: ui.DisplayFeatureType.fold,
        state: ui.DisplayFeatureState.postureFlat,
      );
      tester.view.displayFeatures = const [reported];
      final feed = _TestFeed()
        ..report(_reading(FoldHingeStatus.partiallyOpen, active: true));
      late List<ui.DisplayFeature> features;
      await tester.pumpWidget(
        FoldScopeHost(
          feed: feed,
          child: w.Builder(
            builder: (context) {
              features = w.MediaQuery.displayFeaturesOf(context);

              return const w.SizedBox.shrink();
            },
          ),
        ),
      );

      expect(features, const [reported]);
    });

    testWidgets('keeps what the platform reports beside the fold', (
      tester,
    ) async {
      _showViewport(tester, _wide);
      const cutout = ui.DisplayFeature(
        bounds: Rect.fromLTWH(900, 20, 30, 30),
        type: ui.DisplayFeatureType.cutout,
        state: ui.DisplayFeatureState.unknown,
      );
      tester.view.displayFeatures = const [cutout];
      final feed = _TestFeed()
        ..report(_reading(FoldHingeStatus.partiallyOpen, active: true));
      late List<ui.DisplayFeature> features;
      await tester.pumpWidget(
        FoldScopeHost(
          feed: feed,
          child: w.Builder(
            builder: (context) {
              features = w.MediaQuery.displayFeaturesOf(context);

              return const w.SizedBox.shrink();
            },
          ),
        ),
      );

      expect(features, hasLength(2));
      expect(features.first, cutout);
      expect(features.last.bounds, _divisionWide);
    });

    testWidgets('asks again when the app comes back to the foreground', (
      tester,
    ) async {
      final feed = _TestFeed();
      await tester.pumpWidget(
        FoldScopeHost(feed: feed, child: const w.SizedBox.shrink()),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(feed.refreshes, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(feed.refreshes, 1);
    });

    testWidgets('stops watching when it goes', (tester) async {
      final feed = _TestFeed();
      await tester.pumpWidget(
        FoldScopeHost(feed: feed, child: const w.SizedBox.shrink()),
      );
      expect(feed.watchers, 1);
      await tester.pumpWidget(const w.SizedBox.shrink());

      expect(feed.watchers, 0);
    });

    testWidgets('is its child on a platform with nothing to ask', (
      tester,
    ) async {
      // Android — the default target of a test — reports folds itself.
      await tester.pumpWidget(
        const FoldScopeHost(child: w.SizedBox(key: _content)),
      );

      expect(
        find.ancestor(
          of: find.byKey(_content),
          matching: find.byType(w.MediaQuery),
        ),
        // The view's own, and none of the host's.
        findsOneWidget,
      );
    });
  });

  group("on iOS the host reads the package's plugin", () {
    const channel = MethodChannel('coui_flutter/fold');

    Future<void> pumpReader(
      WidgetTester tester,
      void Function(CoreFoldLayout layout) onLayout,
    ) => tester.pumpWidget(
      FoldScopeHost(
        child: w.Builder(
          builder: (context) {
            onLayout(FoldScope.of(context));

            return const w.SizedBox.shrink();
          },
        ),
      ),
    );

    testWidgets('asks once mounted and follows what the plugin says next', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _showViewport(tester, _wide);
      final asked = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        asked.add(call.method);

        return _message('fullyOpen');
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      late CoreFoldLayout layout;
      await pumpReader(tester, (value) => layout = value);
      await tester.pump();

      expect(asked, ['read']);
      expect(layout.posture, CoreFoldPosture.flat);

      // The plugin tells Dart when the hinge comes to rest partly open.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          MethodCall('changed', _message('partiallyOpen', active: true)),
        ),
        (_) {},
      );
      await tester.pump();

      expect(layout.posture, CoreFoldPosture.book);
      expect(layout.isSplit, isTrue);

      debugDefaultTargetPlatformOverride = null;
    });

    // A channel no plugin registered answers with a missing-plugin error: a
    // widget test, a simulator build made before the plugin existed, an app
    // that embeds Flutter without registering plugins. The test binding
    // leaves an unmocked call unanswered instead, so the answer is given
    // here.
    for (final (name, failure) in <(String, Exception)>[
      ('nothing answers', MissingPluginException()),
      (
        'the plugin cannot measure',
        PlatformException(code: 'unavailable'),
      ),
    ]) {
      testWidgets('reads no fold, and reports no error, where $name', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        _showViewport(tester, _wide);
        var asked = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            asked += 1;
            throw failure;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        late CoreFoldLayout layout;
        await pumpReader(tester, (value) => layout = value);
        await tester.pump();

        expect(asked, 1);
        expect(layout.folds, isEmpty);
        expect(tester.takeException(), isNull);

        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('CoUIApp mounts the host: a dialog opens on one side of a '
        'folding iPhone held like a book', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _showViewport(tester, _wide);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => _message('partiallyOpen', active: true),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      for (final direction in w.TextDirection.values) {
        late w.BuildContext app;
        await tester.pumpWidget(
          CoUIApp(
            key: w.ValueKey(direction),
            locale: direction == w.TextDirection.rtl
                ? const Locale('ar')
                : const Locale('en', 'US'),
            supportedLocales: const [Locale('ar'), Locale('en', 'US')],
            theme: ThemeData.fromCore(CoreThemePresets.light),
            home: w.Builder(
              builder: (context) {
                app = context;

                return const w.SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();
        unawaited(
          showDialog<void>(
            context: app,
            builder: (_) => const Dialog(
              content: w.SizedBox(key: _content, width: 120, height: 60),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final layout = FoldScope.of(app);
        final start = layout.startSegmentIndex(
          direction == w.TextDirection.rtl
              ? CoreTextDirection.rtl
              : CoreTextDirection.ltr,
        )!;
        final segment = layout.segments[start];
        final content = tester.getRect(find.byKey(_content));
        expect(layout.segments, hasLength(2));
        expect(start, direction == w.TextDirection.rtl ? 1 : 0);
        expect(
          content.left >= segment.left && content.right <= segment.right,
          isTrue,
          reason:
              'the dialog ($content) lies inside segment $start '
              '($segment), $direction',
        );
      }

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
