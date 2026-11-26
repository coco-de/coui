// Frame timing, scene by scene and tier by tier, on a real device in profile
// mode.
//
// Not a pass/fail test — a measurement. Adaptive quality trades the glass for
// smoothness, and every number the governor decides by (the ladder's order,
// the budget multiples that call a window over or comfortable) is a guess until
// it has been set against what each tier actually costs. This file draws the
// same scenes at each tier and reports the distribution of the frames' build
// and raster times, so the guess can be replaced by a number measured on the
// hardware that matters.
//
// ## Why profile mode, and why a driver
//
// Debug mode is not a performance mode: assertions and an unoptimised engine
// make every number meaningless. `flutter test` has no `--profile`; `flutter
// drive` has, and the driver (`test_driver/frame_timing_driver.dart`) is also
// what carries the result off the device as JSON. Run it through the
// orchestrator (`tool/frame_timing/frame_timing.dart`), which also measures the
// Web, records the machine and writes the CSV; or by hand:
//
//   flutter drive --profile -d macos \
//     --driver=test_driver/frame_timing_driver.dart \
//     --target=integration_test/frame_timing_test.dart \
//     --dart-define=FT_SCENES=glass-grid-5,glass-chain-20 \
//     --dart-define=FT_TIERS=full,noRefraction,solid \
//     --dart-define=FT_SECONDS=4
//
// `FT_OUT` (environment, read by the driver) is the directory the JSON goes to.
//
// ## What is measured
//
// The engine hands over every frame's timings (`addTimingsCallback`); the
// scene is recorded from just after its warm-up until `FT_SECONDS` have
// passed, and the build, raster and total spans of each frame are summarised
// as P50, P75, P95 and the maximum. Raster is the stage a quality tier can
// lower — the refraction program and the backdrop pass run there — which is why
// the adaptive governor reads it, and why the report keeps the three apart.
//
// The tier is stated the way an app states it: `CoUIApp(adaptiveQuality:
// CoreAdaptiveQuality(forced: tier))`, so the measurement goes through the
// shipped seat rather than around it.
//
// ## The scenes
//
// Every scene draws a moving backdrop, because glass over a still picture
// re-blurs nothing: the cost is the blur of what is under it *this frame*.
//
//   glass-grid-N     N non-overlapping glass cards (N = 1, 5, 20, 50)
//   glass-chain-N    N overlapping glass cards, each over the last, so every
//                    backdrop pass reads the one before it (N = 5, 20)
//   swipe-list-N     N `SwipeActions` rows scrolling under a glass header
//                    (N = 100, 1000)
//   drawer-open      a drawer opened over the backdrop and left open
//   menu-open        a context menu opened over the backdrop and left open
//
// And two that are not CoUI surfaces, so a tier does not apply to them (run
// them at one tier): the bound on what sharing the backdrop could save.
//
//   blur-plain-N     N plain backdrop blurs, each reading the backdrop itself
//   blur-group-N     the same N, all reading one copy of it (`BackdropGroup`)
//
// A scene that starts something (a scroll, a drawer) is recorded from the
// start of it, so the opening is part of what is measured.

import 'dart:async';
import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Which scenes to run; empty is all of them.
const String kScenes = String.fromEnvironment('FT_SCENES');

/// Which tiers to draw each scene at.
const String kTiers = String.fromEnvironment(
  'FT_TIERS',
  defaultValue: 'full,noRefraction,solid',
);

/// How long each scene is recorded, in seconds.
const int kSeconds = int.fromEnvironment('FT_SECONDS', defaultValue: 4);

/// How long each scene runs before the recording starts, in milliseconds:
/// shaders compile, caches fill, the clocks come up.
const int kWarmupMs = int.fromEnvironment('FT_WARMUP_MS', defaultValue: 1500);

/// A scene: what it draws, and what it does once it is up.
class _Scene {
  const _Scene(this.name, this.build, [this.drive]);

  final String name;

  /// The widget the scene is.
  final Widget Function() build;

  /// What the scene does once drawn, recorded; null for one that only moves.
  /// Returns when the seconds given have passed.
  final Future<void> Function(WidgetTester tester, int seconds)? drive;
}

/// Glass cards placed by [place], over the moving backdrop.
Widget _cards(int count, Offset Function(int index) place, Size size) => Stack(
  children: [
    const Positioned.fill(child: _Backdrop()),
    for (var i = 0; i < count; i++)
      Positioned(
        left: place(i).dx,
        top: place(i).dy,
        width: size.width,
        height: size.height,
        child: Card(child: Center(child: Text('${i + 1}'))),
      ),
  ],
);

/// [count] plain backdrop blurs over the moving backdrop — each reading the
/// backdrop itself, or all of them reading one copy ([grouped]).
Widget _blurs(int count, {required bool grouped}) {
  final filter = ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16);
  final stack = Stack(
    children: [
      const Positioned.fill(child: _Backdrop()),
      for (var i = 0; i < count; i++)
        Positioned(
          left: _gridCell(i).dx,
          top: _gridCell(i).dy,
          width: 88,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: grouped
                ? BackdropFilter.grouped(
                    filter: filter,
                    child: const SizedBox.expand(),
                  )
                : BackdropFilter(
                    filter: filter,
                    child: const SizedBox.expand(),
                  ),
          ),
        ),
    ],
  );

  return grouped ? BackdropGroup(child: stack) : stack;
}

Offset _gridCell(int i) => Offset(16 + (i % 8) * 96.0, 16 + (i ~/ 8) * 56.0);

Offset _chainStep(int i) => Offset(24 + i * 28.0, 24 + i * 14.0);

/// The scenes, by name.
final Map<String, _Scene> _scenes = {
  for (final n in const [1, 5, 20, 50])
    'glass-grid-$n': _Scene(
      'glass-grid-$n',
      () => _cards(n, _gridCell, const Size(88, 48)),
    ),
  for (final n in const [5, 20])
    'glass-chain-$n': _Scene(
      'glass-chain-$n',
      () => _cards(n, _chainStep, const Size(220, 130)),
    ),
  for (final n in const [100, 1000])
    'swipe-list-$n': _Scene(
      'swipe-list-$n',
      () => _SwipeList(rows: n),
      _scrollList,
    ),
  for (final n in const [5, 20, 50]) ...{
    'blur-plain-$n': _Scene(
      'blur-plain-$n',
      () => _blurs(n, grouped: false),
    ),
    'blur-group-$n': _Scene('blur-group-$n', () => _blurs(n, grouped: true)),
  },
  'drawer-open': _Scene(
    'drawer-open',
    () => const _Opener(),
    _openAndHold,
  ),
  'menu-open': _Scene(
    'menu-open',
    () => const _MenuStage(),
    (tester, seconds) async {
      await tester.tapAt(
        tester.getCenter(find.byKey(_kMenuTarget)),
        buttons: kSecondaryButton,
      );
      await _wait(tester, seconds * 1000);
    },
  ),
};

const Key _kMenuTarget = ValueKey<String>('frame-timing-menu-target');
const Key _kList = ValueKey<String>('frame-timing-list');
const Key _kOpener = ValueKey<String>('frame-timing-opener');

/// Real time, with the engine producing frames. [WidgetTester.runAsync] so the
/// wait is wall-clock whichever binding policy is in force.
Future<void> _wait(WidgetTester tester, int milliseconds) async {
  await tester.runAsync(
    () => Future<void>.delayed(Duration(milliseconds: milliseconds)),
  );
}

/// A glass header over rows that are scrolled up and down at a steady speed.
Future<void> _scrollList(WidgetTester tester, int seconds) async {
  final state = tester.state<_SwipeListState>(find.byType(_SwipeList));
  final controller = state.controller;
  const speed = 2400.0; // logical pixels per second
  const chunk = Duration(milliseconds: 500);
  var direction = 1.0;
  final stop = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(stop)) {
    final max = controller.position.maxScrollExtent;
    var target = controller.offset + direction * speed * 0.5;
    if (target > max) {
      target = max;
      direction = -1;
    } else if (target < 0) {
      target = 0;
      direction = 1;
    }
    await controller.animateTo(target, duration: chunk, curve: Curves.linear);
  }
}

/// Opens a drawer from the stage's navigator and holds it open.
Future<void> _openAndHold(WidgetTester tester, int seconds) async {
  final context = tester.element(find.byKey(_kOpener));
  unawaited(
    openDrawer<void>(
      context: context,
      side: CoreDrawerSide.bottom,
      builder: (context) => Drawer(
        side: CoreDrawerSide.bottom,
        title: 'Frame timing',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < 6; i++) Text('Row ${i + 1}')],
        ),
      ),
    ),
  );
  await _wait(tester, seconds * 1000);
}

/// Everything the scenes draw glass over.
class _Backdrop extends StatefulWidget {
  const _Backdrop();

  @override
  State<_Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<_Backdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _BlobPainter(_controller),
      size: Size.infinite,
    ),
  );
}

/// Soft saturated blobs drifting over a dark field — content that changes
/// every frame, which is what a backdrop blur has to re-read.
class _BlobPainter extends CustomPainter {
  _BlobPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _colors = [
    Color(0xFFE8334A),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFA855F7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E0E10),
    );
    final t = animation.value * 2 * math.pi;
    for (var i = 0; i < 14; i++) {
      final phase = i * 0.9;
      final center = Offset(
        size.width * (0.5 + 0.42 * math.sin(t + phase)),
        size.height * (0.5 + 0.40 * math.cos(1.3 * t + phase * 1.7)),
      );
      canvas.drawCircle(
        center,
        46 + 18 * math.sin(t * 2 + phase),
        Paint()..color = _colors[i % _colors.length],
      );
    }
    // Hard edges: a bend and a blur have something crisp to move.
    final line = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => true;
}

/// Rows of [SwipeActions] under a glass header.
class _SwipeList extends StatefulWidget {
  const _SwipeList({required this.rows});

  final int rows;

  @override
  State<_SwipeList> createState() => _SwipeListState();
}

class _SwipeListState extends State<_SwipeList> {
  final ScrollController controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: _Backdrop()),
      Positioned.fill(
        child: ListView.builder(
          key: _kList,
          controller: controller,
          padding: const EdgeInsets.only(top: 88),
          itemExtent: 72,
          itemCount: widget.rows,
          itemBuilder: (context, i) => SwipeActions(
            trailingActions: [
              CoreSwipeAction(
                label: 'Archive',
                icon: const Icon(LucideIcons.archive),
                onPressed: () {},
              ),
            ],
            child: Basic(
              leading: const Icon(LucideIcons.mail),
              title: Text('Row ${i + 1}'),
              subtitle: const Text('Scrolling under the glass'),
            ),
          ),
        ),
      ),
      const Positioned(
        left: 16,
        right: 16,
        top: 16,
        height: 56,
        child: Card(child: Center(child: Text('Glass header'))),
      ),
    ],
  );
}

/// A backdrop with a button-sized place to open a drawer from.
class _Opener extends StatelessWidget {
  const _Opener();

  @override
  Widget build(BuildContext context) => const Stack(
    children: [
      Positioned.fill(child: _Backdrop()),
      Center(child: SizedBox(key: _kOpener, width: 8, height: 8)),
    ],
  );
}

/// A backdrop with a context menu's target in the middle.
class _MenuStage extends StatelessWidget {
  const _MenuStage();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: _Backdrop()),
      Center(
        child: ContextMenu(
          items: [
            CoreMenuItem.action('Copy', onPressed: () {}),
            CoreMenuItem.action('Paste', onPressed: () {}),
            const CoreMenuItem.divider(),
            CoreMenuItem.action('Delete', onPressed: () {}),
          ],
          child: const SizedBox(key: _kMenuTarget, width: 240, height: 120),
        ),
      ),
    ],
  );
}

/// The percentile summary of one stage's durations, in microseconds.
Map<String, int> _summary(List<int> micros) {
  final sorted = [...micros]..sort();
  if (sorted.isEmpty) return {'p50': 0, 'p75': 0, 'p95': 0, 'max': 0};

  return {
    'p50': CoreFrameStats.percentile(sorted, 50),
    'p75': CoreFrameStats.percentile(sorted, 75),
    'p95': CoreFrameStats.percentile(sorted, 95),
    'max': sorted.last,
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final wantedScenes = kScenes.isEmpty
      ? _scenes.keys.toList()
      : kScenes.split(',').map((name) => name.trim()).toList();
  final unknown = wantedScenes.where((name) => !_scenes.containsKey(name));
  if (unknown.isNotEmpty) {
    throw ArgumentError(
      'unknown scenes ${unknown.toList()}; '
      'known: ${_scenes.keys.toList()}',
    );
  }
  final tiers = [
    for (final name in kTiers.split(','))
      CoreQualityTier.values.byName(name.trim()),
  ];

  testWidgets(
    'frame timing',
    (tester) async {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      // The program is compiled before the first scene is drawn, so the first
      // scene does not pay for it.
      await tester.runAsync(SurfaceRefractionProgram.warmUp);
      final results = <Map<String, Object?>>[];

      for (final name in wantedScenes) {
        final scene = _scenes[name]!;
        for (final tier in tiers) {
          await tester.pumpWidget(
            CoUIApp(
              theme: ThemeData.fromCore(CoreThemePresets.dark),
              themeMode: CoreThemeMode.dark,
              surfaceStyle: CoreSurfaceStyleId.liquidGlass,
              adaptiveQuality: CoreAdaptiveQuality(forced: tier),
              home: scene.build(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await _wait(tester, kWarmupMs);

          final build = <int>[];
          final raster = <int>[];
          final total = <int>[];
          void record(List<ui.FrameTiming> timings) {
            for (final timing in timings) {
              build.add(timing.buildDuration.inMicroseconds);
              raster.add(timing.rasterDuration.inMicroseconds);
              total.add(timing.totalSpan.inMicroseconds);
            }
          }

          SchedulerBinding.instance.addTimingsCallback(record);
          final drive = scene.drive;
          if (drive == null) {
            await _wait(tester, kSeconds * 1000);
          } else {
            await drive(tester, kSeconds);
          }
          // The engine reports in batches; let the last one arrive.
          await _wait(tester, 400);
          SchedulerBinding.instance.removeTimingsCallback(record);

          final view = tester.view;
          final hz = view.display.refreshRate;
          final budget = (Duration.microsecondsPerSecond / hz).round();
          results.add({
            'scene': name,
            'tier': tier.name,
            'frames': total.length,
            'refreshHz': hz,
            'budgetMicros': budget,
            'build': _summary(build),
            'raster': _summary(raster),
            'total': _summary(total),
            'rasterOverBudget': raster.where((r) => r > budget).length,
          });
          debugPrint(
            'FT  $name  ${tier.name}  frames=${total.length}  '
            'raster p95=${_summary(raster)['p95']}us',
          );
          // One line per result, so a run that fails part-way can still be
          // read from the log.
          debugPrint('FTJSON ${jsonEncode(results.last)}');

          await tester.pumpWidget(const SizedBox.shrink());
        }
      }

      binding.reportData = {
        'results': results,
        'machine': {
          'os': Platform.operatingSystemVersion,
          'processors': Platform.numberOfProcessors,
          'devicePixelRatio': tester.view.devicePixelRatio,
          'mode': kReleaseMode
              ? 'release'
              : kProfileMode
              ? 'profile'
              : 'debug',
          'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        },
        'settings': {
          'seconds': kSeconds,
          'warmupMs': kWarmupMs,
          'tiers': [for (final tier in tiers) tier.name],
        },
      };
    },
    timeout: Timeout.none,
  );
}
