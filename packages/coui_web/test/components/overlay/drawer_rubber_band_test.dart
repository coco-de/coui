// A Web drawer dragged past its dock: the markup the entry emits for a
// stretched panel and for its return, the pose it reads back from the browser
// when a pointer takes hold of a panel that is still on its way, and that
// none of it reaches a drawer that did not ask for a rubber band.
//
// The drag itself needs a real `web.PointerEvent`, real layout and a real
// pointer capture, which the VM does not have (see `drawer_sheet_test.dart`),
// so the pointer path is judged in Chrome by
// `tool/parity/test/web/drawer_rubber_band_probe_test.dart`, which puts the
// shipped drawer through the same vector table coui_core and the Flutter
// drawer are held to.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/drawer/drawer_pose.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The vector table shared with Core, the Flutter drawer and the Chrome probe
/// (cwd is `packages/coui_web` under `dart test`).
const String kDrawerRubberBandVectorsPath =
    '../coui_core/test/fixtures/drawer_rubber_band_vectors.json';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// Opens [drawer] over a real [OverlayHost] the way a page does.
class _DrawerOpener extends StatefulComponent {
  const _DrawerOpener(this.drawer);

  final Drawer drawer;

  @override
  State<_DrawerOpener> createState() => _DrawerOpenerState();
}

class _DrawerOpenerState extends State<_DrawerOpener> {
  @override
  void initState() {
    super.initState();
    // Deferred like every real caller: mounting notifies the host, and a
    // host `setState` reached from inside build throws.
    unawaited(
      Future<void>.microtask(() {
        if (!mounted) return;
        unawaited(
          openDrawer<void>(
            context: context,
            side: component.drawer.side,
            builder: (close) => component.drawer,
          ),
        );
      }),
    );
  }

  @override
  Component build(BuildContext context) => const span([], id: 'opener');
}

Future<void> _open(ComponentTester tester, Drawer drawer) async {
  tester.pumpComponent(
    Theme.defaults(child: OverlayHost(child: _DrawerOpener(drawer))),
  );
  await tester.pump();
}

/// The rendered drawer panel — the only element carrying `role="dialog"`.
DomComponent _panel() =>
    find
            .byComponentPredicate(
              (c) => c is DomComponent && c.attributes?['role'] == 'dialog',
            )
            .evaluate()
            .single
            .component
        as DomComponent;

/// The scale a `transform` value puts the slide axis at.
double _scaleOf(String transform) {
  final match = RegExp(r'scale[XY]\(([-0-9.e]+)\)$').firstMatch(transform);
  expect(match, isNotNull, reason: 'no scale in "$transform"');

  return double.parse(match!.group(1)!);
}

double _num(Object? value) => (value! as num).toDouble();

const Map<CoreDrawerSide, String> kOrigins = {
  CoreDrawerSide.left: 'left center',
  CoreDrawerSide.right: 'right center',
  CoreDrawerSide.top: 'center top',
  CoreDrawerSide.bottom: 'center bottom',
};

void main() {
  final doc =
      jsonDecode(File(kDrawerRubberBandVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final stretchCases =
      ((doc['stretch']! as Map<String, Object?>)['cases']! as List)
          .cast<Map<String, Object?>>();
  final gestures = doc['gestures']! as Map<String, Object?>;
  final gestureCases = (gestures['cases']! as List)
      .cast<Map<String, Object?>>();

  /// The panel's inline styles for one state of the entry.
  Map<String, String> panelStyles(
    BuildContext context,
    CoreDrawerSide side, {
    bool open = true,
    double dragDelta = 0,
    bool rubberBand = true,
    double stretch = 0,
    double stretchExtent = 0,
    bool settling = false,
  }) => resolveDrawer(
    context,
    side: side,
    open: open,
    dragDelta: dragDelta,
    rubberBand: rubberBand,
    stretch: stretch,
    stretchExtent: stretchExtent,
    settling: settling,
  ).panel.inlineStyles!.properties;

  group('Drawer.rubberBand', () {
    test('is off by default, on the widget, the contract and the resolver', () {
      expect(CoreDrawerContract.defaultRubberBand, isFalse);
      expect(
        const Drawer(content: Component.text('x')).rubberBand,
        CoreDrawerContract.defaultRubberBand,
      );
    });

    test('copyWith carries the flag', () {
      const drawer = Drawer(content: Component.text('x'));

      expect(drawer.copyWith(rubberBand: true).rubberBand, isTrue);
      expect(drawer.copyWith().rubberBand, isFalse);
    });

    testComponents('a panel states the origin its stretch is anchored at', (
      tester,
    ) async {
      for (final side in CoreDrawerSide.values) {
        await _open(
          tester,
          Drawer(
            side: side,
            rubberBand: true,
            content: const Component.text('body'),
          ),
        );

        expect(
          _panel().styles!.properties['transform-origin'],
          kOrigins[side],
          reason: side.name,
        );
      }
    });

    testComponents('a panel without it states no origin at all', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .bottom, content: Component.text('body')),
      );

      expect(_panel().styles!.properties, isNot(contains('transform-origin')));
    });

    testComponents('keeps the pointer wiring of a draggable panel', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          rubberBand: true,
          content: Component.text('body'),
        ),
      );

      expect(
        _panel().events!.keys,
        containsAll(<String>[
          'pointerdown',
          'pointermove',
          'pointerup',
          'pointercancel',
        ]),
      );
      expect(_panel().styles!.properties['touch-action'], 'none');
    });
  });

  group('a drawer without a rubber band is exactly what it was', () {
    for (final side in CoreDrawerSide.values) {
      testComponents('${side.name}: the stretch arguments reach nothing', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final plain = panelStyles(context, side, rubberBand: false);
        // A caller (or a stale state) that states a stretch and a return
        // without asking for the rubber band gets the plain panel back.
        final stated = panelStyles(
          context,
          side,
          rubberBand: false,
          stretch: 20,
          stretchExtent: 300,
          settling: true,
        );

        expect(stated, plain);
        expect(plain['transform'], 'translateX(0) translateY(0)');
        expect(plain, isNot(contains('transform-origin')));
        expect(plain['transition'], startsWith('transform '));
        expect(
          plain['transition'],
          contains('var(--coui-duration-350)'),
          reason: 'the slide keeps its own duration',
        );
      });

      testComponents('${side.name}: the default call is the plain one', (
        tester,
      ) async {
        final context = _themedContext(tester);

        // The resolver's new arguments default to nothing.
        expect(
          resolveDrawer(
            context,
            side: side,
            open: true,
            dragDelta: 0,
          ).panel.inlineStyles!.properties,
          panelStyles(context, side, rubberBand: false),
        );
      });
    }
  });

  group('a stretched panel, against the shared vectors', () {
    for (final side in CoreDrawerSide.values) {
      final horizontal =
          side == CoreDrawerSide.left || side == CoreDrawerSide.right;

      for (final c in stretchCases.where((c) => _num(c['stretch']) > 0)) {
        testComponents('${side.name}: ${c['name']}', (tester) async {
          final context = _themedContext(tester);
          final styles = panelStyles(
            context,
            side,
            stretch: _num(c['stretch']),
            stretchExtent: _num(c['extent']),
          );

          // The scale the table states, on the axis the panel slides along.
          expect(
            styles['transform'],
            startsWith(
              'translateX(0) translateY(0) '
              'scale${horizontal ? 'X' : 'Y'}(',
            ),
          );
          expect(
            _scaleOf(styles['transform']!),
            closeTo(_num(c['scale']), 1e-6),
          );
          // The finger is the animation: nothing eases a stretch.
          expect(styles['transition'], 'none');
          expect(styles['transform-origin'], kOrigins[side]);
        });
      }
    }

    testComponents('a stretch with no extent is not drawn', (tester) async {
      final context = _themedContext(tester);

      expect(
        panelStyles(context, .bottom, stretch: 20)['transform'],
        'translateX(0) translateY(0)',
      );
    });

    testComponents('a panel on its way out is not stretched', (tester) async {
      final context = _themedContext(tester);
      final styles = panelStyles(
        context,
        .bottom,
        open: false,
        stretch: 20,
        stretchExtent: 300,
      );

      expect(styles['transform'], 'translateY(100%)');
      expect(styles['transition'], startsWith('transform '));
    });

    testComponents('a slide stays a translation, with the transition off', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final styles = panelStyles(context, .bottom, dragDelta: 40);

      expect(styles['transform'], 'translateY(${40 / kRemDivisor}rem)');
      expect(styles['transition'], 'none');
    });

    for (final c in gestureCases) {
      testComponents('the pose the gesture "${c['name']}" leaves', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final pose = c['pose']! as Map<String, Object?>;
        final stretch = _num(pose['stretch']);
        final slide = _num(pose['slide']);
        final extent = _num(gestures['extent']);
        final styles = panelStyles(
          context,
          .bottom,
          dragDelta: slide,
          stretch: stretch,
          stretchExtent: extent,
        );

        // Where the entry sends a pose: a stretch as a scale of
        // (extent + stretch) / extent, a slide as a translation, never both.
        if (stretch > 0) {
          expect(
            (_scaleOf(styles['transform']!) - 1) * extent,
            closeTo(stretch, 1e-3),
          );
        } else {
          expect(styles['transform'], contains('translateY('));
          expect(styles['transform'], isNot(contains('scale')));
        }
      });
    }
  });

  group('the return to the dock', () {
    for (final side in CoreDrawerSide.values) {
      testComponents('${side.name}: takes the rubber band duration and curve', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final settling = panelStyles(context, side, settling: true);
        final slide = panelStyles(context, side);

        // The same cubic Bezier Flutter drives through `Cubic`, over the
        // transition-tier token Core states.
        final ms = CoreDrawerRubberBand.defaultSettleDuration.inMilliseconds;
        expect(
          settling['transition'],
          'transform var(--coui-duration-$ms) var(--easing-ease-out)',
        );
        expect(
          slide['transition'],
          isNot(settling['transition']),
          reason: 'the slide-in keeps the slide duration',
        );
        // At rest, so the transition has a place to go.
        expect(settling['transform'], 'translateX(0) translateY(0)');
        expect(settling['transform-origin'], kOrigins[side]);
      });
    }

    testComponents('is the easing alias for arrival, as a CSS variable', (
      tester,
    ) async {
      expect(CoreDrawerRubberBand.defaultSettleEasing, CoreEasing.enter);
      expect(
        CoreDrawerRubberBand.defaultSettleEasing.toVarCss(),
        'var(--easing-ease-out)',
      );
      expect(
        CoreDrawerRubberBand.defaultSettleEasing.toCss(),
        'cubic-bezier(0.0, 0.0, 0.58, 1.0)',
      );
    });

    testComponents('is a token the reduced-motion media query zeroes', (
      tester,
    ) async {
      // `durationMsCss` hands a transition-tier token back as a variable,
      // and the stylesheet sets every such variable to 0 under
      // `prefers-reduced-motion`; a literal millisecond count would escape it.
      final ms = CoreDrawerRubberBand.defaultSettleDuration.inMilliseconds;

      expect(durationMsCss(ms), 'var(--coui-duration-$ms)');
      expect(
        CoreReducedMotion.isTransitionMotion(Duration(milliseconds: ms)),
        isTrue,
      );
      expect(
        ThemeConfig.defaults().cssVariables,
        contains('--coui-duration-$ms'),
      );
    });
  });

  group('the pose a computed transform puts a panel in', () {
    const extent = 300.0;
    CoreDrawerPose read(String? css, CoreDrawerSide side) =>
        drawerPoseOf(css, side: side, extent: extent);

    test('none, nothing and nonsense are a panel at its dock', () {
      for (final css in [
        null,
        '',
        'none',
        'garbage',
        'matrix(1, 0, 0)',
        'a(b)',
      ]) {
        for (final side in CoreDrawerSide.values) {
          expect(read(css, side), CoreDrawerRubberBand.rest, reason: '$css');
        }
      }
    });

    test('a scale on the slide axis is a stretch of the figure it adds', () {
      final pose = read('matrix(1, 0, 0, 1.05, 0, 0)', .bottom);
      expect(pose.slide, 0);
      expect(pose.stretch, closeTo(15, 1e-9));
      expect(
        read('matrix(1.1, 0, 0, 1, 0, 0)', .left).stretch,
        closeTo(30, 1e-9),
      );
      expect(
        read('matrix(1.1, 0, 0, 1, 0, 0)', .right).stretch,
        closeTo(30, 1e-9),
      );
      expect(
        read('matrix(1, 0, 0, 1.02, 0, 0)', .top).stretch,
        closeTo(6, 1e-9),
      );
    });

    test('the scale of the other axis is no stretch', () {
      expect(
        read('matrix(1.1, 0, 0, 1, 0, 0)', .bottom),
        CoreDrawerRubberBand.rest,
      );
      expect(
        read('matrix(1, 0, 0, 1.1, 0, 0)', .left),
        CoreDrawerRubberBand.rest,
      );
    });

    test('a shift toward the edge the panel hides behind is a slide', () {
      expect(read('matrix(1, 0, 0, 1, 0, 40)', .bottom).slide, 40);
      expect(read('matrix(1, 0, 0, 1, 0, -40)', .top).slide, 40);
      expect(read('matrix(1, 0, 0, 1, 40, 0)', .right).slide, 40);
      expect(read('matrix(1, 0, 0, 1, -40, 0)', .left).slide, 40);
    });

    test('a shift the other way is not a slide', () {
      expect(
        read('matrix(1, 0, 0, 1, 0, -40)', .bottom),
        CoreDrawerRubberBand.rest,
      );
      expect(
        read('matrix(1, 0, 0, 1, 40, 0)', .left),
        CoreDrawerRubberBand.rest,
      );
    });

    test('a 3D matrix is read from its own layout', () {
      const stretched =
          'matrix3d(1, 0, 0, 0, 0, 1.05, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)';
      const slid = 'matrix3d(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 40, 0, 1)';

      expect(read(stretched, .bottom).stretch, closeTo(15, 1e-9));
      expect(read(slid, .bottom).slide, 40);
      expect(read(slid, .left), CoreDrawerRubberBand.rest);
    });

    test('reads back what the resolver wrote, for every row of the table', () {
      for (final c in stretchCases.where((c) => _num(c['stretch']) > 0)) {
        final scale = _num(c['scale']);
        final read = drawerPoseOf(
          'matrix(1, 0, 0, $scale, 0, 0)',
          side: .bottom,
          extent: _num(c['extent']),
        );

        expect(
          read.stretch,
          closeTo(_num(c['stretch']), 1e-3),
          reason: '${c['name']}',
        );
      }
    });

    test('hands the pull a pointer carries on from', () {
      // A panel 14 px stretched, taken hold of: the pull that puts it there.
      final pose = read('matrix(1, 0, 0, ${1 + 14 / extent}, 0, 0)', .bottom);
      final pull = CoreDrawerRubberBand.pullOf(pose, extent: extent);

      expect(pull, lessThan(0));
      expect(
        CoreDrawerRubberBand.poseOf(pull, extent: extent).stretch,
        closeTo(14, 1e-9),
      );
    });
  });
}
