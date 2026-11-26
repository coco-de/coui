// A ContextMenu can lift its child off the page while the menu is open
// (`liftChild`, opt-in): a held touch raises the child before the menu appears,
// any other opening raises it as the menu appears, and every way of closing
// plays it backwards while the menu folds into the child.
//
// The judgements are Core's (`CoreContextMenuLift`,
// `CoreContextMenuLiftTimeline` and `CoreContextMenuRetract`) and one shared
// table (`context_menu_lift_vectors.json`) pins them: the Core test replays it
// on the functions, the Flutter test as pointer events on a real menu, and this
// file replays every trace the Web is named in on the touch tracker and the
// lift with a manual clock - the clock, the press events and the frames are the
// only things a browser supplies - and reads the CSS the resolver gives for the
// progress each sample states.
//
// What a VM can pin is the tracker, the lift's bookkeeping, the resolvers and
// the markup. What it cannot is the page: the source measured off layout, the
// copy promoted into the top layer under the panel, the frames of a real
// `requestAnimationFrame`, `inert`, the computed style at a moment of a real
// touch. That half is read off a live page by a real Chrome (`tool/parity`).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_lift.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_lift_layer.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_press.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/context_menu_lift_vectors.json';

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

double _num(Object? value) => (value! as num).toDouble();

Map<String, String> _css(Styles? styles) => styles?.properties ?? const {};

/// A clock wound by hand: it tells the time, fires timers that fall due and
/// holds the frames that were asked for until the test says a frame has come.
final class _Clock {
  int _ms = 0;
  final List<_ManualTimer> _timers = [];
  final List<_Frame> _frames = [];

  Duration now() => Duration(milliseconds: _ms);

  Timer timer(Duration delay, void Function() callback) {
    final timer = _ManualTimer(_ms + delay.inMilliseconds, callback);
    _timers.add(timer);

    return timer;
  }

  void Function() requestFrame(void Function() callback) {
    final frame = _Frame(callback);
    _frames.add(frame);

    return () => frame.withdrawn = true;
  }

  /// How many frames are waiting to be drawn.
  int get pendingFrames => _frames.where((f) => !f.withdrawn).length;

  void advanceTo(int target) {
    while (true) {
      final due =
          _timers
              .where((timer) => timer.isActive && timer.dueAt <= target)
              .toList()
            ..sort((left, right) => left.dueAt.compareTo(right.dueAt));
      if (due.isEmpty) break;
      _ms = due.first.dueAt;
      due.first.fire();
    }
    _ms = target;
  }

  /// A frame comes: every frame that was asked for is drawn, once.
  void drawFrame() {
    final waiting = _frames.where((f) => !f.withdrawn).toList();
    _frames.clear();
    for (final frame in waiting) {
      frame.callback();
    }
  }
}

final class _Frame {
  _Frame(this.callback);

  final void Function() callback;
  bool withdrawn = false;
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.dueAt, this._callback);

  final int dueAt;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

/// The stand-in for the host that the table is replayed through: a touch
/// tracker and a lift wired the way the component wires them, on a manual
/// clock, with a record of the calls the tracker made on the lift.
final class _Host {
  _Host({this.duration = CoreContextMenuStyle.defaultLiftDuration}) {
    press = ContextMenuPress(
      timer: _clock.timer,
      onHoldStart: () {
        final lift = _create();
        if (lift.begin(held: true)) {
          _lift = lift;
          calls.add((at: _clock._ms, call: 'begin held'));
        }
      },
      onHoldCancel: () {
        calls.add((at: _clock._ms, call: 'release'));
        _lift?.release();
      },
      onOpen: (x, y) {
        calls.add((at: _clock._ms, call: 'commit'));
        _lift?.commit();
      },
    );
  }

  final Duration duration;
  final _Clock _clock = _Clock();
  late final ContextMenuPress press;
  final List<({int at, String call})> calls = [];
  int rests = 0;
  ContextMenuLift? _lift;

  ContextMenuLift? get lift => _lift;

  ContextMenuLift _create() => ContextMenuLift(
    duration: duration,
    now: _clock.now,
    requestFrame: _clock.requestFrame,
    onFrame: (_) {},
    onRest: () {
      rests++;
      _lift?.dispose();
      _lift = null;
    },
  );

  /// An opening with no hold (a right click, a key, a controller).
  void open() {
    _lift?.dispose();
    final lift = _create();
    if (lift.begin(held: false)) {
      _lift = lift;
      calls.add((at: _clock._ms, call: 'begin'));
    }
  }

  void close(int ms) {
    calls.add((at: _clock._ms, call: 'close'));
    _lift?.close(Duration(milliseconds: ms));
  }

  double get progress => _lift?.progress ?? 0;
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final numbers = doc['numbers']! as Map<String, Object?>;
  final restyled = doc['override']! as Map<String, Object?>;
  final other = restyled['numbers']! as Map<String, Object?>;
  final closeMs = (numbers['closeMs']! as num).toInt();

  /// The style the `override` block states, with the rise a trace names.
  CoreContextMenuStyle styleWith({required Duration rise}) =>
      CoreContextMenuStyle(
        liftScale: _num(other['liftScale']),
        liftDuration: rise,
        liftDimOpacity: _num(other['dimOpacity']),
        liftCast: [
          for (final layer in _list(other['cast']))
            (
              offsetX: _num(layer['offsetX']),
              offsetY: _num(layer['offsetY']),
              blurRadius: _num(layer['blurRadius']),
              spreadRadius: _num(layer['spreadRadius']),
              opacity: _num(layer['opacity']),
              inset: false,
            ),
        ],
        liftRadius: CoreBorderRadius.all(_num(other['radius'])),
        retractScale: _num(other['retractScale']),
      );

  /// Mounts [child] under a theme that states [theme] for every context menu.
  void pumpUnder(
    ComponentTester tester,
    Component child, {
    CoreContextMenuTheme? theme,
  }) {
    tester.pumpComponent(
      Theme(
        data: ThemeData.coui.copyWith(
          coreComponentTheme: theme == null
              ? null
              : CoreComponentTheme(contextMenu: theme),
        ),
        child: child,
      ),
    );
  }

  /// What a menu under [style] (its own) and [theme] (every menu's) settles.
  ResolvedContextMenu resolveMenu(
    ComponentTester tester, {
    CoreContextMenuStyle? style,
    CoreContextMenuTheme? theme,
  }) {
    late ResolvedContextMenu result;
    pumpUnder(
      tester,
      Builder(
        builder: (context) {
          result = resolveContextMenu(context, contextMenuStyle: style);

          return const div([]);
        },
      ),
      theme: theme,
    );

    return result;
  }

  /// The chrome [resolveContextMenuLift] gives at [progress], for the numbers
  /// a menu under [style] and [theme] settles.
  ResolvedContextMenuLift resolveLift(
    ComponentTester tester,
    double progress, {
    ContextMenuLiftBox source = (left: 40, top: 30, width: 320, height: 200),
    CoreContextMenuStyle? style,
    CoreContextMenuTheme? theme,
  }) {
    late ResolvedContextMenuLift result;
    pumpUnder(
      tester,
      Builder(
        builder: (context) {
          result = resolveContextMenuLift(
            context,
            progress: progress,
            source: source,
            runtime: resolveContextMenu(
              context,
              contextMenuStyle: style,
            ).runtime,
          );

          return const div([]);
        },
      ),
      theme: theme,
    );

    return result;
  }

  /// The layer over [lift], with the numbers the default menu settles unless
  /// [runtime] says otherwise.
  Component layerOf({
    required String id,
    required ContextMenuLift lift,
    required Component child,
    ResolvedContextMenuRuntime? runtime,
  }) => Builder(
    builder: (context) => ContextMenuLiftLayer(
      id: id,
      lift: lift,
      runtime: runtime ?? resolveContextMenu(context).runtime,
      child: child,
    ),
  );

  /// `scale(1.0151)` -> 1.0151.
  double scaleOf(String transform) => double.parse(
    RegExp(r'^scale\(([\d.]+)\)$').firstMatch(transform)!.group(1)!,
  );

  /// `rgb(var(--coui-scrim) / 0.0756)` -> 0.0756.
  double dimOf(String color) => double.parse(
    RegExp(r'/ ([\d.]+)\)$').firstMatch(color)!.group(1)!,
  );

  /// Replays [trace] on the touch tracker and the lift with a manual clock,
  /// and reads the CSS the resolver gives for the progress each sample states
  /// - for a menu under [style] (its own) and [theme] (every menu's), which
  /// state the numbers the samples were written against.
  void replayTrace(
    ComponentTester tester,
    Map<String, Object?> trace, {
    CoreContextMenuStyle? style,
    CoreContextMenuTheme? theme,
  }) {
    // The rise the clock runs over is what the resolver settles for this menu
    // (the component reads it the same way), not a number the test chose.
    final settled = resolveMenu(tester, style: style, theme: theme);
    final host = _Host(duration: settled.runtime.liftDuration);
    final clock = host._clock;
    final events = _list(trace['events']);
    final samples = _list(trace['samples']);
    final times = {
      for (final e in events) e['at']! as int,
      for (final s in samples) s['at']! as int,
    }.toList()..sort();

    for (final time in times) {
      clock.advanceTo(time);

      for (final event in events.where((e) => e['at'] == time)) {
        switch (event['kind']! as String) {
          case 'down':
            host.press.down(_num(event['x']), _num(event['y']));
          case 'move':
            host.press.move(_num(event['x']), _num(event['y']));
          case 'up' || 'cancel':
            host.press.end();
          case 'scroll':
            host.press.scrolled();
          case 'open':
            host.open();
          case 'close':
            host.close(closeMs);
          case final kind:
            fail('the table gave the Web an event it cannot replay: $kind');
        }
      }

      // A frame comes at every sample.
      clock.drawFrame();
      for (final sample in samples.where(
        (sample) => sample['at'] == time,
      )) {
        final where = '${trace['name']} at $time ms';
        final progress = _num(sample['progress']);
        expect(host.progress, closeTo(progress, 1e-9), reason: where);

        // The CSS that progress is drawn as.
        final chrome = resolveLift(
          tester,
          host.progress,
          style: style,
          theme: theme,
        );
        final copy = _css(chrome.copy.inlineStyles);
        expect(
          scaleOf(copy['transform']!),
          closeTo(_num(sample['scale']), 1e-6),
          reason: '$where: scale of the copy',
        );
        expect(
          dimOf(_css(chrome.dim.inlineStyles)['background-color']!),
          closeTo(_num(sample['dim']), 1e-4),
          reason: '$where: dim over the page',
        );
      }
    }

    // The tracker made the calls on the lift that the table says a seat
    // makes - and at the times it says. A release after the hold paid off
    // is nothing to the lift, and the tracker, which stops reporting a
    // hold once it has paid off, never makes one.
    final expected = <({int at, String call})>[];
    for (final call in _list(trace['timeline'])) {
      final name = call['call']! as String;
      if (name == 'release' && expected.any((e) => e.call == 'commit')) {
        continue;
      }
      expected.add((at: call['at']! as int, call: name));
    }
    final seen = [
      for (final call in host.calls)
        (at: call.at, call: call.call.replaceFirst(' held', '')),
    ];
    expect(
      seen,
      expected,
      reason: '${trace['name']}: what the tracker told the lift',
    );
  }

  group('every trace of the shared table the Web is named in', () {
    final traces = _list(doc['traces']);

    for (final trace in traces) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;

      testComponents(
        '${trace['name']}',
        (tester) async => replayTrace(tester, trace),
      );
    }
  });

  group('a style that states other numbers, every trace of the table', () {
    Duration riseOf(Map<String, Object?> trace) =>
        Duration(milliseconds: (trace['durationMs']! as num).toInt());

    test('states other numbers than the defaults, in every field', () {
      expect(_num(other['liftScale']), isNot(_num(numbers['liftScale'])));
      expect(_num(other['dimOpacity']), isNot(_num(numbers['dimOpacity'])));
      expect(_num(other['retractScale']), isNot(_num(numbers['retractScale'])));
      expect(_num(other['radius']), isNot(_num(numbers['radius'])));
      expect(_list(other['cast']), isNot(_list(numbers['cast'])));
    });

    for (final trace in _list(restyled['traces'])) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;

      testComponents(
        "${trace['name']} - the menu's own style",
        (tester) async => replayTrace(
          tester,
          trace,
          style: styleWith(rise: riseOf(trace)),
        ),
      );
      testComponents(
        "${trace['name']} - the theme's style",
        (tester) async => replayTrace(
          tester,
          trace,
          theme: CoreContextMenuTheme(style: styleWith(rise: riseOf(trace))),
        ),
      );
    }
  });

  group('the lift', () {
    testComponents('asks for a frame, and one at a time', (tester) async {
      final host = _Host()..open();

      expect(host._clock.pendingFrames, 1);
      host._clock.advanceTo(40);
      host._clock.drawFrame();
      expect(host._clock.pendingFrames, 1, reason: 'the next one');
    });

    testComponents('is parked at the top: no frame until the menu closes', (
      tester,
    ) async {
      final host = _Host()..open();
      host._clock
        ..advanceTo(400)
        ..drawFrame();

      expect(host.progress, 1);
      expect(host._clock.pendingFrames, 0, reason: 'nothing would change');

      host.close(closeMs);
      expect(host._clock.pendingFrames, 1, reason: 'it settles over frames');
      host._clock
        ..advanceTo(400 + closeMs)
        ..drawFrame();
      expect(host.rests, 1, reason: 'and is done when it has settled');
      expect(host._clock.pendingFrames, 0);
    });

    testComponents('a release before the lift began is at rest at once', (
      tester,
    ) async {
      final host = _Host();
      host.press.down(10, 10);
      host._clock.advanceTo(100);
      host.press.end();

      expect(host.rests, 1);
      expect(host.lift, isNull);
      expect(host._clock.pendingFrames, 0, reason: 'no frame for nothing');
    });

    testComponents('a lift with no duration is a jump (reduced motion)', (
      tester,
    ) async {
      final host = _Host(duration: Duration.zero)..press.down(10, 10);
      host._clock
        ..advanceTo(149)
        ..drawFrame();
      expect(host.progress, 0, reason: 'the delay is a wait, not motion');
      host._clock
        ..advanceTo(151)
        ..drawFrame();
      expect(host.progress, 1, reason: 'it arrives at once');

      host.press.end();
      expect(host.rests, 1, reason: 'and leaves at once');
    });

    testComponents('disposing it withdraws the frame it asked for', (
      tester,
    ) async {
      final host = _Host()..open();
      expect(host._clock.pendingFrames, 1);

      host.lift!.dispose();
      expect(host._clock.pendingFrames, 0);
    });

    testComponents('tells its listeners after every frame and remeasure', (
      tester,
    ) async {
      final host = _Host()..open();
      var heard = 0;
      host.lift!.addListener(() => heard++);

      host._clock
        ..advanceTo(30)
        ..drawFrame();
      expect(heard, 1);
      host.lift!.remeasure((left: 1, top: 2, width: 3, height: 4));
      expect(heard, 2);
      expect(host.lift!.source, (left: 1, top: 2, width: 3, height: 4));
    });
  });

  group('the touch tracker tells the host about the hold', () {
    testComponents('once when it starts, not for a second finger', (
      tester,
    ) async {
      var starts = 0;
      final press = ContextMenuPress(
        onOpen: (_, _) {},
        timer: _Clock().timer,
        onHoldStart: () => starts++,
      );

      expect(press.down(1, 1), isTrue);
      expect(press.down(2, 2), isFalse);
      expect(starts, 1);
    });

    testComponents('and when it ends without paying off, every way it can', (
      tester,
    ) async {
      for (final end in <(String, void Function(ContextMenuPress))>[
        ('lifting', (tracker) => tracker.end()),
        ('lifting at a point', (tracker) => tracker.up(1, 1)),
        ('a scroll', (tracker) => tracker.scrolled()),
        ('drifting past the slop', (tracker) => tracker.move(200, 200)),
        ('being cancelled', (tracker) => tracker.cancel()),
        ('being disposed', (tracker) => tracker.dispose()),
      ]) {
        var cancels = 0;
        final press = ContextMenuPress(
          onOpen: (_, _) {},
          timer: _Clock().timer,
          onHoldCancel: () => cancels++,
        )..down(1, 1);

        end.$2(press);
        expect(cancels, 1, reason: end.$1);
      }
    });

    testComponents('but not for a hold that paid off, nor a press never held', (
      tester,
    ) async {
      var cancels = 0;
      final clock = _Clock();
      final press = ContextMenuPress(
        onOpen: (_, _) {},
        timer: clock.timer,
        onHoldCancel: () => cancels++,
      )..end();
      expect(cancels, 0, reason: 'there was no hold');

      press.down(1, 1);
      clock.advanceTo(600);
      press.end();
      expect(cancels, 0, reason: 'the hold had paid off');
    });
  });

  group('the resolver', () {
    testComponents('draws the lift over the page and under the panel', (
      tester,
    ) async {
      final classes = resolveLift(tester, 0.5).root.className.split(' ');

      expect(
        classes,
        containsAll(['fixed', 'inset-0', 'pointer-events-none', 'z-50']),
        reason: 'above the page, below the panel (z-60), out of the way',
      );
    });

    testComponents('places the copy at the box it measured, at its size', (
      tester,
    ) async {
      final css = _css(resolveLift(tester, 0).copy.inlineStyles);

      expect(css['left'], '40px');
      expect(css['top'], '30px');
      expect(css['width'], '320px');
      expect(css['height'], '200px');
      expect(
        resolveLift(tester, 0).copy.className.split(' '),
        containsAll(['absolute', 'pointer-events-none', 'transition-none']),
        reason: 'the page-wide colour and shadow transitions do not reach it',
      );
    });

    testComponents('rounds the box the cast is cast from by the lift radius', (
      tester,
    ) async {
      final copy = resolveLift(tester, 1).copy;

      expect(
        _css(copy.inlineStyles)['border-radius'],
        CoreContextMenuStyle.defaultLiftRadius.toValue(),
        reason:
            'the radius variable, so a style that re-points radii reaches it',
      );
      expect(
        copy.className,
        isNot(contains('rounded-')),
        reason: 'the radius is written once, inline',
      );
    });

    testComponents(
      'casts the stack of the progress, strengthened for the dark',
      (
        tester,
      ) async {
        // Fully lifted the stack is the scale step the contract names, so it
        // is the variable a surface style bends and that carries the dark
        // strength.
        expect(
          _css(resolveLift(tester, 1).copy.inlineStyles)['box-shadow'],
          'var(--shadow-lg)',
        );

        // Any other progress is not a scale step: the contract's layers each
        // scaled by the progress, as literals, with the dark strength on every
        // colour.
        final shadow = _css(
          resolveLift(tester, 0.5).copy.inlineStyles,
        )['box-shadow']!;
        final cast = _list(numbers['cast']).single;
        expect(shadow, isNot(contains('var(--shadow-')));
        expect(shadow, contains('--coui-shadow-strength'));
        expect(shadow, contains('${_num(cast['offsetY']) * 0.5 / 16}rem'));
        expect(shadow, contains('${_num(cast['blurRadius']) * 0.5 / 16}rem'));
      },
    );

    testComponents('dims by the scrim token, to the lift dim at the top', (
      tester,
    ) async {
      final dim = _css(resolveLift(tester, 1).dim.inlineStyles);

      expect(dim['background-color'], startsWith('rgb(var(--coui-scrim) / '));
      expect(
        dimOf(dim['background-color']!),
        closeTo(_num(numbers['dimOpacity']), 1e-9),
      );
      expect(
        resolveLift(tester, 0).dim.className,
        'absolute inset-0 transition-none',
      );
    });

    testComponents('folds a panel by the exit easing about the point given', (
      tester,
    ) async {
      final motion = resolveContextMenuRetractMotion(
        closeDuration: const Duration(milliseconds: 100),
        originX: 12.5,
        originY: 40,
        retractScale: _num(numbers['retractScale']),
      );
      final css = _css(motion.inlineStyles);

      expect(motion.className, 'pointer-events-none');
      expect(css['transform-origin'], '12.50px 40px');
      expect(css['--coui-overlay-retract-scale'], '${numbers['retractScale']}');
      expect(css['animation'], startsWith('co-overlay-retract '));
      expect(css['animation'], contains(CoreEasing.exit.toVarCss()));
      expect(css['animation'], endsWith(' both'));
    });

    testComponents('hides the original only while the copy stands in', (
      tester,
    ) async {
      late ResolvedContextMenu shown;
      late ResolvedContextMenu hidden;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            shown = resolveContextMenu(context);
            hidden = resolveContextMenu(context, liftHidden: true);

            return const div([]);
          },
        ),
      );

      expect(shown.source.className, '');
      expect(hidden.source.className, 'opacity-0');
    });
  });

  group('the resolver under a style that states other numbers', () {
    const rise = Duration(milliseconds: 200);

    /// `rgb(var(--coui-scrim) / 0.35)` -> 0.35, from the dim's chrome.
    double dimAt(ResolvedContextMenuLift chrome) =>
        dimOf(_css(chrome.dim.inlineStyles)['background-color']!);

    testComponents('a menu that states nothing settles the defaults', (
      tester,
    ) async {
      final runtime = resolveMenu(tester).runtime;

      expect(runtime.liftDuration, CoreContextMenuStyle.defaultLiftDuration);
      expect(runtime.liftScale, CoreContextMenuStyle.defaultLiftScale);
      expect(
        runtime.liftDimOpacity,
        CoreContextMenuStyle.defaultLiftDimOpacity,
      );
      expect(runtime.liftCast, CoreContextMenuStyle.defaultLiftCast);
      expect(runtime.liftRadius, CoreContextMenuStyle.defaultLiftRadius);
      expect(runtime.retractScale, CoreContextMenuStyle.defaultRetractScale);
    });

    testComponents("settles the menu's own style", (tester) async {
      final style = styleWith(rise: rise);
      final runtime = resolveMenu(tester, style: style).runtime;

      expect(runtime.liftDuration, rise);
      expect(runtime.liftScale, style.liftScale);
      expect(runtime.liftDimOpacity, style.liftDimOpacity);
      expect(runtime.liftCast, style.liftCast);
      expect(runtime.liftRadius, style.liftRadius);
      expect(runtime.retractScale, style.retractScale);
    });

    testComponents("settles the theme's style for a menu that states none", (
      tester,
    ) async {
      final style = styleWith(rise: rise);
      final runtime = resolveMenu(
        tester,
        theme: CoreContextMenuTheme(style: style),
      ).runtime;

      expect(runtime.liftDuration, rise);
      expect(runtime.liftScale, style.liftScale);
      expect(runtime.liftDimOpacity, style.liftDimOpacity);
      expect(runtime.liftCast, style.liftCast);
      expect(runtime.liftRadius, style.liftRadius);
      expect(runtime.retractScale, style.retractScale);
    });

    testComponents("the menu's own style beats the theme, field by field", (
      tester,
    ) async {
      final theme = CoreContextMenuTheme(style: styleWith(rise: rise));
      final runtime = resolveMenu(
        tester,
        theme: theme,
        style: const CoreContextMenuStyle(
          liftScale: 1.2,
          retractScale: 0.7,
        ),
      ).runtime;

      expect(runtime.liftScale, 1.2);
      expect(runtime.retractScale, 0.7);
      // Not stated by the menu: the theme's.
      expect(runtime.liftDuration, rise);
      expect(runtime.liftDimOpacity, theme.style!.liftDimOpacity);
      expect(runtime.liftCast, theme.style!.liftCast);
      expect(runtime.liftRadius, theme.style!.liftRadius);
    });

    testComponents('draws the copy at the size, dim and corners it states', (
      tester,
    ) async {
      final chrome = resolveLift(tester, 1, style: styleWith(rise: rise));

      expect(
        scaleOf(_css(chrome.copy.inlineStyles)['transform']!),
        closeTo(_num(other['liftScale']), 1e-9),
      );
      expect(dimAt(chrome), closeTo(_num(other['dimOpacity']), 1e-9));
      expect(
        _css(chrome.copy.inlineStyles)['border-radius'],
        CoreBorderRadius.all(_num(other['radius'])).toValue(),
      );
    });

    testComponents('casts the stack it states, not the design default', (
      tester,
    ) async {
      final cast = _list(other['cast']).single;
      // Half way, so the stack is not a scale step whatever it states.
      final shadow = _css(
        resolveLift(
          tester,
          0.5,
          style: styleWith(rise: rise),
        ).copy.inlineStyles,
      )['box-shadow']!;

      expect(shadow, isNot(contains('var(--shadow-')));
      expect(shadow, contains('${_num(cast['offsetY']) * 0.5 / 16}rem'));
      expect(shadow, contains('${_num(cast['blurRadius']) * 0.5 / 16}rem'));
      expect(shadow, contains('${_num(cast['spreadRadius']) * 0.5 / 16}rem'));
      expect(
        shadow,
        isNot(
          contains(
            '${_num(_list(numbers['cast']).single['offsetY']) * 0.5 / 16}rem',
          ),
        ),
        reason: 'the default cast is not drawn',
      );
    });

    testComponents('the theme reaches the copy the same way', (tester) async {
      final chrome = resolveLift(
        tester,
        1,
        theme: CoreContextMenuTheme(style: styleWith(rise: rise)),
      );

      expect(
        scaleOf(_css(chrome.copy.inlineStyles)['transform']!),
        closeTo(_num(other['liftScale']), 1e-9),
      );
      expect(dimAt(chrome), closeTo(_num(other['dimOpacity']), 1e-9));
    });

    testComponents('a size under 1 draws the child at its own size', (
      tester,
    ) async {
      final chrome = resolveLift(
        tester,
        1,
        style: const CoreContextMenuStyle(liftScale: 0.5),
      );

      expect(scaleOf(_css(chrome.copy.inlineStyles)['transform']!), 1);
    });

    testComponents('a dim past 1 is held to 1', (tester) async {
      final chrome = resolveLift(
        tester,
        1,
        style: const CoreContextMenuStyle(liftDimOpacity: 5),
      );

      expect(dimAt(chrome), 1);
    });

    testComponents('folds a panel to the size the style states', (
      tester,
    ) async {
      final runtime = resolveMenu(tester, style: styleWith(rise: rise)).runtime;
      final css = _css(
        resolveContextMenuRetractMotion(
          closeDuration: const Duration(milliseconds: 100),
          originX: 0,
          originY: 0,
          retractScale: runtime.retractScale,
        ).inlineStyles,
      );

      expect(
        css['--coui-overlay-retract-scale'],
        '${_num(other['retractScale'])}',
      );
    });

    testComponents('holds the fold to 0..1 as the engine does', (tester) async {
      String scaleFor(double retractScale) => _css(
        resolveContextMenuRetractMotion(
          closeDuration: const Duration(milliseconds: 100),
          originX: 0,
          originY: 0,
          retractScale: retractScale,
        ).inlineStyles,
      )['--coui-overlay-retract-scale']!;

      expect(scaleFor(2), '1.0', reason: 'a fold never grows the panel');
      expect(scaleFor(-1), '0.0', reason: 'nor mirrors it');
      expect(scaleFor(double.nan), '1.0');
      expect(scaleFor(0.5), '0.5');
    });

    testComponents('the layer draws with the numbers it is handed', (
      tester,
    ) async {
      final host = _Host()..open();
      host.lift!.source = (left: 40, top: 30, width: 320, height: 200);
      host._clock
        ..advanceTo(300)
        ..drawFrame();
      final style = styleWith(rise: rise);
      late ResolvedContextMenuRuntime runtime;
      pumpUnder(
        tester,
        Builder(
          builder: (context) {
            runtime = resolveContextMenu(
              context,
              contextMenuStyle: style,
            ).runtime;

            return layerOf(
              id: 'layer',
              lift: host.lift!,
              runtime: runtime,
              child: const div([]),
            );
          },
        ),
      );
      await tester.pump();

      // The lift is whole at 400 ms with no hold; the layer draws what the
      // handed numbers say of that progress, not the default look.
      host._clock
        ..advanceTo(700)
        ..drawFrame();
      await tester.pump();
      final copy =
          find
                  .byComponentPredicate(
                    (c) =>
                        c is DomComponent &&
                        c.classes?.contains('absolute') == true &&
                        c.id == null,
                  )
                  .evaluate()
                  .last
                  .component
              as DomComponent;
      expect(
        scaleOf(_css(copy.styles)['transform']!),
        closeTo(
          CoreContextMenuLift.scale(
            host.progress,
            liftScale: runtime.liftScale,
          ),
          1e-6,
        ),
      );
      expect(
        scaleOf(_css(copy.styles)['transform']!),
        isNot(closeTo(CoreContextMenuStyle.defaultLiftScale, 1e-3)),
        reason: 'not the design default',
      );
    });
  });

  group('the layer', () {
    ContextMenuLift lifted() {
      final host = _Host()..open();
      host.lift!.source = (left: 40, top: 30, width: 320, height: 200);
      host._clock
        ..advanceTo(300)
        ..drawFrame();

      return host.lift!;
    }

    DomComponent byId(String id) =>
        find
                .byComponentPredicate(
                  (c) => c is DomComponent && c.id == id,
                  description: 'the element $id',
                )
                .evaluate()
                .first
                .component
            as DomComponent;

    testComponents(
      "is a picture: hidden, inert and out of the pointer's way",
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          layerOf(
            id: 'layer',
            lift: lifted(),
            child: const div([], id: 'child'),
          ),
        );
        await tester.pump();

        final layer = byId('layer');
        expect(layer.attributes?['aria-hidden'], 'true');
        expect(layer.attributes?.containsKey('inert'), isTrue);
        expect(layer.classes, contains('pointer-events-none'));
      },
    );

    testComponents('holds a second build of the child over the dim', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        layerOf(
          id: 'layer',
          lift: lifted(),
          child: const div([], id: 'child'),
        ),
      );
      await tester.pump();

      expect(
        find.byComponentPredicate((c) => c is div && c.id == 'child'),
        findsOneComponent,
      );
      final dim = find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            c.attributes?.containsKey('data-coui-lift-dim') == true,
      );
      expect(dim, findsOneComponent);
    });

    testComponents('joins the top layer under a host and not without one', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        layerOf(id: 'layer', lift: lifted(), child: const div([])),
      );
      await tester.pump();
      expect(byId('layer').attributes?['popover'], isNull);

      final hosted = lifted();
      tester.pumpComponent(
        Theme.defaults(
          child: OverlayHost(
            child: layerOf(
              id: 'hosted',
              lift: hosted,
              child: const div([]),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(byId('hosted').attributes?['popover'], 'manual');
      expect(
        byId('hosted').attributes?.containsKey('data-coui-overlay-panel'),
        isTrue,
      );
    });

    testComponents('draws nothing until the source has been measured', (
      tester,
    ) async {
      final host = _Host()..open();
      pumpWithTheme(
        tester,
        layerOf(
          id: 'layer',
          lift: host.lift!,
          child: const div([]),
        ),
      );
      await tester.pump();

      expect(
        find.byComponentPredicate((c) => c is DomComponent && c.id == 'layer'),
        findsNothing,
      );
    });

    testComponents('redraws itself when the lift moves on, and no one else', (
      tester,
    ) async {
      final lift = lifted();
      pumpWithTheme(
        tester,
        layerOf(
          id: 'layer',
          lift: lift,
          child: const div([], id: 'c'),
        ),
      );
      await tester.pump();
      String transform() => _css(
        (find
                    .byComponentPredicate(
                      (c) =>
                          c is DomComponent &&
                          c.classes?.contains('absolute') == true &&
                          c.id == null,
                    )
                    .evaluate()
                    .last
                    .component
                as DomComponent)
            .styles,
      )['transform']!;

      final before = transform();
      lift.remeasure((left: 50, top: 40, width: 320, height: 200));
      await tester.pump();

      expect(transform(), before, reason: 'the same progress, the same size');
      final left = _css(
        (find
                    .byComponentPredicate(
                      (c) =>
                          c is DomComponent &&
                          c.classes?.contains('absolute') == true &&
                          c.id == null,
                    )
                    .evaluate()
                    .last
                    .component
                as DomComponent)
            .styles,
      )['left'];
      expect(left, '50px', reason: 'it follows the source');
    });
  });

  group('the host stylesheet', () {
    testComponents(
      'carries the retract keyframes and the forced-colours rule',
      (
        tester,
      ) async {
        tester.pumpComponent(
          Theme.defaults(child: const OverlayHost(child: div([]))),
        );
        await tester.pump();

        // Raw text, not text: the host's stylesheet has child combinators in
        // it, and a `<style>` is not decoded.
        final css = find
            .byComponentPredicate(
              (c) => c is DomComponent && c.tag == 'style',
              description: 'the host stylesheet',
            )
            .evaluate()
            .expand((e) => (e.component as DomComponent).children ?? const [])
            .whereType<RawText>()
            .map((text) => text.text)
            .join();
        expect(css, contains('@keyframes co-overlay-retract'));
        expect(css, contains('--coui-overlay-retract-scale'));
        expect(css, contains('@media (forced-colors:active)'));
        expect(css, contains('[data-coui-lift-dim]'));
      },
    );
  });

  group('ContextMenu', () {
    ContextMenu menu({bool lift = false}) => ContextMenu(
      items: const [],
      liftChild: lift,
      child: const div([], id: 'child'),
    );

    test('is the contract its Flutter twin implements', () {
      expect(menu(), isA<CoreContextMenuContract<Component>>());
    });

    test('does not lift until asked', () {
      expect(menu().liftChild, isFalse);
      expect(menu(lift: true).liftChild, isTrue);
    });

    test('copyWith carries the option, and keeps it', () {
      final copy = menu().copyWith(liftChild: true);

      expect(copy.liftChild, isTrue);
      expect(copy.copyWith(enabled: false).liftChild, isTrue);
    });

    testComponents(
      'puts the child straight in the root when it does not lift',
      (
        tester,
      ) async {
        pumpWithTheme(tester, menu());
        await tester.pump();

        expect(
          find.byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.id?.startsWith('co-context-menu-source') == true,
          ),
          findsNothing,
        );
        expect(
          find.byComponentPredicate((c) => c is div && c.id == 'child'),
          findsOneComponent,
        );
      },
    );

    testComponents('wraps the child, shown, when it may lift', (tester) async {
      pumpWithTheme(tester, menu(lift: true));
      await tester.pump();

      final source =
          find
                  .byComponentPredicate(
                    (c) =>
                        c is DomComponent &&
                        c.id?.startsWith('co-context-menu-source') == true,
                    description: 'the wrapper of the child',
                  )
                  .evaluate()
                  .single
                  .component
              as DomComponent;
      expect(source.classes ?? '', isNot(contains('opacity-0')));
      expect(
        find.byComponentPredicate((c) => c is div && c.id == 'child'),
        findsOneComponent,
      );
      expect(
        find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              c.id?.startsWith('co-context-menu-lift') == true,
        ),
        findsNothing,
        reason: 'no copy at rest',
      );
    });
  });
}
