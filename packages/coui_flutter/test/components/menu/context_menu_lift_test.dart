// A ContextMenu can lift its child off the page while the menu is open
// (`liftChild`, opt-in): a held touch raises the child before the menu appears,
// any other opening raises it as the menu appears, and every way of closing
// plays it backwards while the menu folds into the child.
//
// What the two seats must agree on is not a framework's animation but a handful
// of numbers at given moments - how far the lift has come a given time after
// the press, what size, shadow and dim that is, how small the folding panel has
// got - and they live in Core (`CoreContextMenuLift`, `CoreContextMenuRetract`)
// and in one shared table (`context_menu_lift_vectors.json`). This file replays
// every trace of that table on a real ContextMenu as pointer events, key events
// and a controller, pumping by the table's durations, and reads what was
// painted: the size of the lifted copy on screen, the colour of the dim, the
// shadow the copy casts, whether the original is hidden. The rest are the
// behaviours the table cannot state: the copy is a picture and not a control,
// the original keeps its place and its state, closing folds the panel toward
// the child by the Core rule and the copy goes in the frame the panel goes,
// and nothing is left behind.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/menu/context_menu/context_menu_lift.dart';
import 'package:flutter/gestures.dart'
    show DeviceGestureSettings, PointerDeviceKind, kSecondaryButton;
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show HitTestResult, RenderObject;
import 'package:flutter/services.dart' show LogicalKeyboardKey, SystemChannels;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/context_menu_lift_vectors.json';

const String _kSelectionClick = 'HapticFeedbackType.selectionClick';

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

double _num(Object? value) => (value! as num).toDouble();

/// Records the haptics the platform was asked for while a test runs.
class _Haptics {
  _Haptics(this.tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          requests.add(call.arguments! as String);
        }

        return null;
      },
    );
  }

  final WidgetTester tester;
  final List<String> requests = [];

  int get ticks => requests.where((r) => r == _kSelectionClick).length;

  void dispose() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}

/// Keeps the states of the counters it builds, in the order they were built,
/// so a test can tell the original's state from the copy's.
class _Counter extends StatefulWidget {
  const _Counter(this.states);

  final List<_CounterState> states;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  /// How many times this state has built, so a test can tell a child that is
  /// built once from one that is built every frame.
  int builds = 0;

  @override
  void initState() {
    super.initState();
    widget.states.add(this);
  }

  @override
  void dispose() {
    widget.states.remove(this);
    super.dispose();
  }

  void increment() => setState(() => count++);

  @override
  Widget build(BuildContext context) {
    builds++;

    return SizedBox(width: 320, height: 200, child: Text('count $count'));
  }
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final numbers = doc['numbers']! as Map<String, Object?>;
  final restyled = doc['override']! as Map<String, Object?>;
  final holdMs = (numbers['holdMs']! as num).toInt();
  final closeMs = (numbers['closeMs']! as num).toInt();

  const regionKey = ValueKey('region');
  const regionWidth = 320.0;
  const regionHeight = 200.0;

  material.Widget buildApp(
    material.Widget child, {
    bool rtl = false,
    bool reduceMotion = false,
    DeviceGestureSettings? gestureSettings,
    Size? size,
    CoreContextMenuTheme? contextMenuTheme,
  }) => material.MaterialApp(
    builder: (context, app) {
      var result = app!;
      if (rtl) {
        result = Directionality(
          textDirection: TextDirection.rtl,
          child: result,
        );
      }
      if (reduceMotion || gestureSettings != null) {
        result = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            gestureSettings: gestureSettings,
          ),
          child: result,
        );
      }

      return result;
    },
    home: Theme(
      data: ThemeData(
        coreComponentTheme: contextMenuTheme == null
            ? null
            : CoreComponentTheme(contextMenu: contextMenuTheme),
      ),
      child: material.Scaffold(body: material.Center(child: child)),
    ),
  );

  /// The region the lift is about, with focus in it so the keyboard opens the
  /// menu there.
  Widget region({Widget? inner}) => Focus(
    autofocus: true,
    child:
        inner ??
        const SizedBox(
          key: regionKey,
          width: regionWidth,
          height: regionHeight,
        ),
  );

  List<CoreMenuItem<Widget>> itemsOf({
    int rows = 3,
    List<String>? activated,
  }) => [
    for (var i = 0; i < rows; i++)
      CoreMenuItem.action(
        'Row $i',
        onPressed: () => activated?.add('Row $i'),
      ),
  ];

  ContextMenu menuOf({
    bool lift = true,
    bool haptics = false,
    bool glide = false,
    int rows = 3,
    List<String>? activated,
    Widget? preview,
    Widget? child,
    PopoverController? controller,
    CoreContextMenuStyle? style,
  }) => ContextMenu(
    items: itemsOf(rows: rows, activated: activated),
    liftChild: lift,
    haptics: haptics,
    glideToSelect: glide,
    preview: preview,
    controller: controller,
    contextMenuStyle: style,
    child: child ?? region(),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> advance(WidgetTester tester, int ms) async {
    if (ms > 0) await tester.pump(Duration(milliseconds: ms));
  }

  // --- reading what is on screen ---------------------------------------

  final liftLayer = find.byType(ContextMenuLiftLayer);
  final follower = find.byType(CompositedTransformFollower);
  final target = find.byType(CompositedTransformTarget);
  final copyRegion = find.descendant(
    of: follower,
    matching: find.byKey(regionKey),
  );
  final originalRegion = find.descendant(
    of: target,
    matching: find.byKey(regionKey),
  );

  /// The original's own wrapper: the one that hides it while the copy is up.
  Finder hiddenWrapper() => find.descendant(
    of: target,
    matching: find.byWidgetPredicate(
      (w) => w is material.Opacity && w.alwaysIncludeSemantics,
    ),
  );

  bool originalHidden(WidgetTester tester) {
    final wrappers = hiddenWrapper();
    if (wrappers.evaluate().isEmpty) return false;

    return tester.widget<material.Opacity>(wrappers.first).opacity == 0;
  }

  /// What the lift looks like right now, or `null` when there is no lift.
  ({double scale, double dim, List<BoxShadow> cast})? lookOf(
    WidgetTester tester,
    Rect source,
  ) {
    if (liftLayer.evaluate().isEmpty) return null;
    final copy = tester.getRect(copyRegion);
    final dim = tester
        .widget<material.ColoredBox>(
          find
              .descendant(
                of: liftLayer,
                matching: find.byType(material.ColoredBox),
              )
              .first,
        )
        .color;
    final cast = tester
        .widget<InjectedCast>(
          find.descendant(of: follower, matching: find.byType(InjectedCast)),
        )
        .shadows;

    return (scale: copy.width / source.width, dim: dim.a, cast: cast);
  }

  /// Checks [look] against a table sample.
  void expectLook(
    ({double scale, double dim, List<BoxShadow> cast})? look,
    Map<String, Object?> sample,
    String where,
  ) {
    final progress = _num(sample['progress']);
    if (progress == 0) {
      // At rest: nothing, or an invisible copy.
      if (look != null) {
        expect(look.scale, closeTo(1, 1e-6), reason: '$where: scale at rest');
        expect(look.dim, closeTo(0, 0.004), reason: '$where: dim at rest');
      }

      return;
    }
    expect(look, isNotNull, reason: '$where: the copy should be up');
    expect(
      look!.scale,
      closeTo(_num(sample['scale']), 1e-6),
      reason: '$where: scale of the copy',
    );
    expect(
      look.dim,
      closeTo(_num(sample['dim']), 0.004),
      reason: '$where: dim over the page',
    );
    final cast = _list(sample['cast']);
    expect(look.cast, hasLength(cast.length), reason: '$where: cast layers');
    for (var i = 0; i < cast.length; i++) {
      final layer = cast[i];
      final shadow = look.cast[i];
      expect(
        shadow.offset.dx,
        closeTo(_num(layer['offsetX']), 1e-4),
        reason: '$where: cast x',
      );
      expect(
        shadow.offset.dy,
        closeTo(_num(layer['offsetY']), 1e-4),
        reason: '$where: cast y',
      );
      expect(
        shadow.blurRadius,
        closeTo(cssBlurRadiusToFlutter(_num(layer['blurRadius'])), 1e-4),
        reason: '$where: cast blur',
      );
      expect(
        shadow.spreadRadius,
        closeTo(_num(layer['spreadRadius']), 1e-4),
        reason: '$where: cast spread',
      );
      expect(
        shadow.color.a,
        closeTo(_num(layer['opacity']), 0.004),
        reason: '$where: cast opacity',
      );
    }
  }

  // --- the table, replayed ------------------------------------------------

  /// Replays [trace] on a real ContextMenu as pointer events, key events and a
  /// controller, pumping by the table's durations, and checks what was painted
  /// at each sample - under [style] (the menu's own) and [theme] (every context
  /// menu's), which state the numbers the samples were written against.
  Future<void> replayTrace(
    WidgetTester tester,
    Map<String, Object?> trace, {
    bool rtl = false,
    CoreContextMenuStyle? style,
    CoreContextMenuTheme? theme,
  }) async {
    final controller = PopoverController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildApp(
        menuOf(controller: controller, style: style),
        rtl: rtl,
        contextMenuTheme: theme,
      ),
    );
    await settle(tester);

    final source = tester.getRect(find.byKey(regionKey));
    Offset at(Map<String, Object?> event) =>
        source.topLeft + Offset(_num(event['x']), _num(event['y']));

    final events = _list(trace['events']);
    final samples = _list(trace['samples']);
    final times = {
      for (final e in events) e['at']! as int,
      for (final s in samples) s['at']! as int,
    }.toList()..sort();

    TestGesture? gesture;
    var now = 0;
    for (final time in times) {
      await advance(tester, time - now);
      now = time;

      for (final event in events.where((e) => e['at'] == time)) {
        switch (event['kind']! as String) {
          case 'down':
            gesture = await tester.startGesture(at(event));
            // The clock of the lift starts at the first frame after.
            await tester.pump();
          case 'move':
            await gesture!.moveTo(at(event));
          case 'up':
            await gesture!.up();
          case 'cancel':
            await gesture!.cancel();
          case 'open':
            switch (event['via']! as String) {
              case 'secondaryClick':
                final click = await tester.startGesture(
                  at(event),
                  kind: PointerDeviceKind.mouse,
                  buttons: kSecondaryButton,
                );
                await click.up();
              case 'key':
                await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
              case 'controller':
                controller.show();
              case final via:
                fail(
                  'the table opened a menu in a way Flutter cannot: $via',
                );
            }
            await tester.pump();
          case 'close':
            switch (event['via']! as String) {
              case 'escape':
                await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              case 'outside':
                await tester.tapAt(const Offset(8, 8));
              case 'controller':
                controller.close();
              case final via:
                fail(
                  'the table closed a menu in a way Flutter cannot: $via',
                );
            }
            await tester.pump();
          case final kind:
            fail(
              'the table gave Flutter an event it cannot replay: $kind',
            );
        }
      }

      for (final sample in samples.where((s) => s['at'] == time)) {
        final where = '${trace['name']} at $time ms';
        expect(tester.takeException(), isNull, reason: where);
        final look = lookOf(tester, source);
        expectLook(look, sample, where);
        // The original is hidden exactly while the copy is up: in no
        // frame are both on screen, or neither.
        expect(
          originalHidden(tester),
          look != null,
          reason: '$where: the original hides while the copy stands in',
        );
      }
    }

    // However the trace ended, everything is put away in the end.
    await gesture?.up().catchError((Object _) {});
    await settle(tester);
    await tester.tapAt(const Offset(8, 8));
    await settle(tester);
    expect(liftLayer, findsNothing);
    expect(originalHidden(tester), isFalse);
  }

  group('every trace of the shared table', () {
    final traces = _list(doc['traces']);

    for (final rtl in [false, true]) {
      for (final trace in traces) {
        final platforms = (trace['platforms'] as List?)?.cast<String>();
        if (platforms != null && !platforms.contains('flutter')) continue;

        testWidgets(
          '${trace['name']}${rtl ? ' (right-to-left)' : ''}',
          (tester) => replayTrace(tester, trace, rtl: rtl),
        );
      }
    }
  });

  /// Presses the region, holds it until the menu is up and the lift has come
  /// to rest, and returns the gesture still down.
  Future<TestGesture> holdOpen(
    WidgetTester tester, {
    Offset offset = const Offset(60, 50),
  }) async {
    final source = tester.getRect(find.byKey(regionKey));
    final gesture = await tester.startGesture(source.topLeft + offset);
    await tester.pump();
    await advance(tester, holdMs);
    await advance(tester, 300);

    return gesture;
  }

  group('defaults', () {
    testWidgets('a ContextMenu that does not lift builds none of it', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf(lift: false)));
      await settle(tester);
      final before = target.evaluate().length;

      final gesture = await holdOpen(tester);
      expect(find.byType(Menu), findsOneWidget);
      expect(liftLayer, findsNothing);
      expect(find.byType(ContextMenuRetract), findsNothing);
      expect(target.evaluate().length, before);
      expect(
        find.byWidgetPredicate(
          (w) => w is material.Opacity && w.alwaysIncludeSemantics,
        ),
        findsNothing,
      );
      await gesture.up();
      await settle(tester);
    });

    testWidgets('the numbers are the ones the table states', (tester) async {
      // The look is the Style's, the gesture the contract's.
      expect(CoreContextMenuStyle.defaultLiftScale, numbers['liftScale']);
      expect(
        CoreContextMenuContract.defaultLiftDelay.inMilliseconds,
        numbers['delayMs'],
      );
      expect(
        CoreContextMenuStyle.defaultLiftDuration.inMilliseconds,
        numbers['durationMs'],
      );
      expect(
        CoreContextMenuStyle.defaultRetractScale,
        numbers['retractScale'],
      );
      expect(
        CoreContextMenuContract.defaultLiftsWithoutHold,
        numbers['liftsWithoutHold'],
      );
    });

    testWidgets('a menu that states nothing resolves to the defaults', (
      tester,
    ) async {
      late ResolvedContextMenu resolved;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              resolved = resolveContextMenu(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.liftScale, CoreContextMenuStyle.defaultLiftScale);
      expect(resolved.liftDuration, CoreContextMenuStyle.defaultLiftDuration);
      expect(
        resolved.liftDimOpacity,
        CoreContextMenuStyle.defaultLiftDimOpacity,
      );
      expect(resolved.liftCast, CoreContextMenuStyle.defaultLiftCast);
      expect(
        resolved.liftRadius,
        BorderRadius.circular(CoreRadiusRole.surface),
      );
      expect(resolved.retractScale, CoreContextMenuStyle.defaultRetractScale);
    });
  });

  group('the copy', () {
    testWidgets(
      'is a second build of the child at the original place and size',
      (
        tester,
      ) async {
        final states = <_CounterState>[];
        await tester.pumpWidget(
          buildApp(menuOf(child: region(inner: _Counter(states)))),
        );
        await settle(tester);
        expect(states, hasLength(1), reason: 'one build at rest');
        final original = states.single..increment();
        await tester.pump();
        expect(original.count, 1);
        final source = tester.getRect(find.byType(_Counter));

        // A right click lifts together with the menu.
        final click = await tester.startGesture(
          source.topLeft + const Offset(60, 50),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await click.up();
        await tester.pump();
        await advance(tester, 400);

        expect(states, hasLength(2), reason: 'the child is built twice');
        expect(identical(states.first, original), isTrue);
        expect(states.last.count, 0, reason: 'the copy starts from nothing');
        expect(original.count, 1, reason: 'the original keeps its state');
        final copy = tester.getRect(
          find.descendant(of: follower, matching: find.byType(_Counter)),
        );
        // Centred on the original, scaled about its middle.
        expect(copy.center.dx, closeTo(source.center.dx, 1e-6));
        expect(copy.center.dy, closeTo(source.center.dy, 1e-6));
        expect(copy.width, closeTo(source.width * 1.04, 1e-6));
        expect(
          tester.getRect(
            find.descendant(of: target, matching: find.byType(_Counter)),
          ),
          source,
          reason: 'the original keeps its place in the layout',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        expect(states, hasLength(1), reason: 'the copy is gone');
        expect(identical(states.single, original), isTrue);
        expect(original.count, 1, reason: 'state survived open and retract');
      },
    );

    testWidgets(
      'redraws its transform, cast and dim from frame to frame, not the child',
      (
        tester,
      ) async {
        final states = <_CounterState>[];
        await tester.pumpWidget(
          buildApp(menuOf(child: region(inner: _Counter(states)))),
        );
        await settle(tester);
        final original = states.single;
        expect(original.builds, 1);
        final source = tester.getRect(find.byType(_Counter));

        final click = await tester.startGesture(
          source.topLeft + const Offset(60, 50),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await click.up();
        // The whole rise, a frame at a time.
        var resized = 0;
        double? last;
        _CounterState? copy;
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (states.length == 2) {
            copy ??= states.last;
            expect(
              identical(states.last, copy),
              isTrue,
              reason: 'frame $i: the same copy, not a new build of the child',
            );
            final width = tester
                .getRect(
                  find.descendant(
                    of: follower,
                    matching: find.byType(_Counter),
                  ),
                )
                .width;
            if (last != null && width != last) resized++;
            last = width;
          }
        }
        expect(copy, isNotNull, reason: 'the copy was drawn');
        expect(resized, greaterThan(5), reason: 'the copy did change size');
        expect(copy!.builds, 1, reason: 'built once for the whole rise');
        expect(original.builds, 1, reason: 'the original is not rebuilt');

        // And the whole fold.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(copy.builds, 1, reason: 'nor is it rebuilt as it settles');
        expect(original.builds, 1);
      },
    );

    testWidgets('is not interactive, not focusable and not announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        buildApp(
          menuOf(
            child: Focus(
              autofocus: true,
              child: Semantics(
                label: 'source',
                button: true,
                child: GestureDetector(
                  onTap: () => taps++,
                  child: const SizedBox(
                    key: regionKey,
                    width: regionWidth,
                    height: regionHeight,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      expect(find.bySemanticsLabel('source'), findsOneWidget);

      final click = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 400);
      expect(liftLayer, findsOneWidget);

      // Announced once: the original, which is hidden but still there.
      expect(find.bySemanticsLabel('source'), findsOneWidget);
      expect(originalHidden(tester), isTrue);
      final ignoring = tester.widget<IgnorePointer>(
        find
            .descendant(of: liftLayer, matching: find.byType(IgnorePointer))
            .first,
      );
      expect(ignoring.ignoring, isTrue);
      expect(
        tester
            .widget<ExcludeSemantics>(
              find
                  .descendant(
                    of: liftLayer,
                    matching: find.byType(ExcludeSemantics),
                  )
                  .first,
            )
            .excluding,
        isTrue,
      );
      // The node in the copy cannot take focus; the original's still has it.
      final copyFocus = Focus.of(tester.element(copyRegion));
      final originalFocus = Focus.of(tester.element(originalRegion));
      expect(copyFocus.canRequestFocus, isFalse);
      expect(originalFocus.canRequestFocus, isTrue);

      // No pointer event can land on the copy's boxes.
      final copyBox = tester.renderObject<RenderObject>(copyRegion);
      final hit = HitTestResult();
      tester.binding.hitTestInView(
        hit,
        source.center,
        tester.view.viewId,
      );
      expect(
        hit.path.any((entry) => identical(entry.target, copyBox)),
        isFalse,
        reason: 'the copy sits in the way of a pointer',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(taps, 0);
      handle.dispose();
    });

    testWidgets('wears the theme of the place it was lifted from', (
      tester,
    ) async {
      // The copy lives in the root overlay, outside the subtree the child was
      // in, and has to be given what that subtree gave the child.
      await tester.pumpWidget(
        buildApp(
          menuOf(
            child: region(
              inner: Builder(
                builder: (context) => SizedBox(
                  key: regionKey,
                  width: regionWidth,
                  height: regionHeight,
                  child: Text('${Theme.of(context).hashCode}'),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final click = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 400);

      final texts = find.byType(Text);
      final inCopy = find.descendant(of: follower, matching: texts);
      final inOriginal = find.descendant(of: target, matching: texts);
      expect(
        tester.widget<Text>(inCopy.first).data,
        tester.widget<Text>(inOriginal.first).data,
        reason: 'the copy read the same theme as the original',
      );
    });
  });

  group('closing', () {
    /// Opens with a right click, lets the lift come to rest and returns where
    /// the panel is.
    Future<({Rect source, Rect panel})> openAndRest(
      WidgetTester tester,
    ) async {
      final source = tester.getRect(find.byKey(regionKey));
      final click = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 500);

      return (source: source, panel: tester.getRect(find.byType(Menu)));
    }

    double panelOpacity(WidgetTester tester) => tester
        .widget<material.Opacity>(
          find
              .ancestor(
                of: find.byType(Menu),
                matching: find.byType(material.Opacity),
              )
              .first,
        )
        .opacity;

    /// Folds `rest` about the pivot the Core rule gives for [source].
    Rect folded(Rect rest, Rect source, double scale) {
      final centre = rest.center;
      final pivot = Offset(
        centre.dx.clamp(source.left, source.right),
        centre.dy.clamp(source.top, source.bottom),
      );

      return Rect.fromLTRB(
        pivot.dx + (rest.left - pivot.dx) * scale,
        pivot.dy + (rest.top - pivot.dy) * scale,
        pivot.dx + (rest.right - pivot.dx) * scale,
        pivot.dy + (rest.bottom - pivot.dy) * scale,
      );
    }

    final curve = _list(doc['retractCurve']);

    /// Samples the panel at the table's fractions of the close and checks the
    /// fold, the dim and the copy, then that everything is put away together.
    Future<void> expectRetract(
      WidgetTester tester,
      Rect source,
      Rect panel, {
      required String via,
    }) async {
      expect(tester.takeException(), isNull, reason: via);
      var at = 0;
      for (final row in curve) {
        final fraction = _num(row['fraction']);
        final ms = (fraction * closeMs).round();
        if (ms >= closeMs) break; // the end is checked below
        await advance(tester, ms - at);
        at = ms;
        final reason = '$via, ${(fraction * 100).round()}% through the close';
        expect(
          panelOpacity(tester),
          closeTo(_num(row['opacity']), 1e-6),
          reason: '$reason: panel opacity',
        );
        final now = tester.getRect(find.byType(Menu));
        final scale = now.width / panel.width;
        expect(
          scale,
          closeTo(_num(row['scale']), 1e-6),
          reason: '$reason: panel scale',
        );
        final want = folded(panel, source, scale);
        expect(
          now.left,
          closeTo(want.left, 1e-4),
          reason: '$reason: panel left',
        );
        expect(now.top, closeTo(want.top, 1e-4), reason: '$reason: panel top');
        expect(
          now.right,
          closeTo(want.right, 1e-4),
          reason: '$reason: panel right',
        );
        expect(
          now.bottom,
          closeTo(want.bottom, 1e-4),
          reason: '$reason: panel bottom',
        );
        // The copy and the panel are up together; the original is hidden.
        expect(liftLayer, findsOneWidget, reason: '$reason: the copy is up');
        expect(originalHidden(tester), isTrue, reason: '$reason: original');
      }

      // One frame at a time to the end: the panel, the copy and the hiding of
      // the original go in the same frame - never one without the others.
      for (var ms = at + 1; ms <= closeMs + 50; ms += 1) {
        await tester.pump(const Duration(milliseconds: 1));
        final panelUp = find.byType(Menu).evaluate().isNotEmpty;
        final copyUp = liftLayer.evaluate().isNotEmpty;
        final hidden = originalHidden(tester);
        expect(
          {panelUp, copyUp, hidden},
          hasLength(1),
          reason:
              '$via: ${ms}ms into the close - panel $panelUp, copy $copyUp, '
              'original hidden $hidden',
        );
        if (!panelUp) break;
      }
      await settle(tester);
      expect(find.byType(Menu), findsNothing);
      expect(liftLayer, findsNothing);
      expect(originalHidden(tester), isFalse);
      expect(tester.takeException(), isNull, reason: via);
    }

    for (final via in ['escape', 'outside', 'controller']) {
      testWidgets(
        'by $via folds the panel into the source and sets the copy down',
        (
          tester,
        ) async {
          final controller = PopoverController();
          addTearDown(controller.dispose);
          await tester.pumpWidget(buildApp(menuOf(controller: controller)));
          await settle(tester);
          final opened = await openAndRest(tester);
          expect(liftLayer, findsOneWidget);

          switch (via) {
            case 'escape':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            case 'outside':
              await tester.tapAt(const Offset(8, 8));
            case 'controller':
              controller.close();
          }
          await tester.pump();

          await expectRetract(tester, opened.source, opened.panel, via: via);
        },
      );
    }

    testWidgets('by activating a row folds and runs the row', (tester) async {
      final activated = <String>[];
      await tester.pumpWidget(buildApp(menuOf(activated: activated)));
      await settle(tester);
      final opened = await openAndRest(tester);

      await tester.tap(find.text('Row 1'));
      await tester.pump();

      expect(activated, ['Row 1']);
      await expectRetract(
        tester,
        opened.source,
        opened.panel,
        via: 'activation',
      );
    });

    testWidgets('a glide that lifts over nothing folds like any close', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf(glide: true)));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
      );
      await tester.pump();
      await advance(tester, holdMs);
      await advance(tester, 300);
      final panel = tester.getRect(find.byType(Menu));

      // The finger leaves the menu altogether and lifts: the glide closes it.
      await gesture.moveTo(const Offset(8, 8));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      await expectRetract(tester, source, panel, via: 'glide release');
    });

    testWidgets('the panel folds toward the nearest point of the source', (
      tester,
    ) async {
      // Open at the bottom-right corner of the region so the panel hangs
      // outside it; the pivot is then an edge point of the source, not the
      // panel's middle.
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final click = await tester.startGesture(
        source.bottomRight - const Offset(10, 10),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 500);
      final panel = tester.getRect(find.byType(Menu));
      expect(
        panel.center.dx > source.right || panel.center.dy > source.bottom,
        isTrue,
        reason: 'the test needs the panel to be beside the source',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await advance(tester, closeMs ~/ 2);

      final now = tester.getRect(find.byType(Menu));
      final scale = now.width / panel.width;
      final want = folded(panel, source, scale);
      expect(now.left, closeTo(want.left, 1e-4));
      expect(now.top, closeTo(want.top, 1e-4));
      await settle(tester);
    });

    testWidgets('a panel folds with the preview beside it', (tester) async {
      await tester.pumpWidget(
        buildApp(
          menuOf(
            preview: const SizedBox(
              key: ValueKey('preview'),
              width: 120,
              height: 80,
            ),
          ),
        ),
      );
      await settle(tester);
      final opened = await openAndRest(tester);
      final previewRest = tester.getRect(find.byKey(const ValueKey('preview')));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await advance(tester, closeMs ~/ 2);

      final scale =
          tester.getRect(find.byType(Menu)).width / opened.panel.width;
      expect(scale, lessThan(1));
      // Both fold about the one point, by the one scale.
      final want = folded(opened.panel, opened.source, scale);
      final panelNow = tester.getRect(find.byType(Menu));
      expect(panelNow.left, closeTo(want.left, 1e-4));
      final pivotX = opened.panel.center.dx.clamp(
        opened.source.left,
        opened.source.right,
      );
      final pivotY = opened.panel.center.dy.clamp(
        opened.source.top,
        opened.source.bottom,
      );
      final previewNow = tester.getRect(find.byKey(const ValueKey('preview')));
      expect(previewNow.width / previewRest.width, closeTo(scale, 1e-6));
      expect(
        previewNow.left,
        closeTo(pivotX + (previewRest.left - pivotX) * scale, 1e-4),
      );
      expect(
        previewNow.top,
        closeTo(pivotY + (previewRest.top - pivotY) * scale, 1e-4),
      );
      await settle(tester);
      expect(find.byKey(const ValueKey('preview')), findsNothing);
    });
  });

  group('a touch that is not a hold', () {
    testWidgets('a tap never shows the lift', (tester) async {
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final tap = await tester.startGesture(source.center);
      await tester.pump();
      await advance(tester, 80);
      await tap.up();
      await settle(tester);

      expect(liftLayer, findsNothing);
      expect(originalHidden(tester), isFalse);
      expect(find.byType(Menu), findsNothing);
    });

    testWidgets(
      'a scroll that takes the touch sets the lift down, '
      'even with a smaller slop',
      (
        tester,
      ) async {
        // The scroll under the finger claims the touch at 8 logical pixels,
        // the hold gives up at 18: for a while the long press has lost the
        // arena and says nothing about it.
        await tester.pumpWidget(
          buildApp(
            SizedBox(
              height: 400,
              child: ListView(
                children: [
                  menuOf(),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
            gestureSettings: const DeviceGestureSettings(touchSlop: 8),
          ),
        );
        await settle(tester);
        final source = tester.getRect(find.byKey(regionKey));

        final gesture = await tester.startGesture(source.center);
        await tester.pump();
        await advance(tester, 300);
        expect(liftLayer, findsOneWidget, reason: 'the lift is up while held');

        await gesture.moveBy(const Offset(0, -12));
        await tester.pump();
        await advance(tester, 16);
        // The scroll took it: the lift is coming back.
        await advance(tester, 400);
        expect(liftLayer, findsNothing);
        expect(originalHidden(tester), isFalse);
        expect(find.byType(Menu), findsNothing);
        await gesture.up();
        await settle(tester);
        expect(find.byType(Menu), findsNothing);
      },
    );

    testWidgets('moving inside the slop keeps the hold and the lift', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await tester.startGesture(source.center);
      await tester.pump();
      await advance(tester, 200);
      await gesture.moveBy(const Offset(4, 4));
      await tester.pump();
      await advance(tester, 400);

      expect(find.byType(Menu), findsOneWidget);
      expect(liftLayer, findsOneWidget);
      await gesture.up();
      await settle(tester);
    });
  });

  group('haptics', () {
    testWidgets('one tick as the hold commits, none for the other openings', (
      tester,
    ) async {
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);
      await tester.pumpWidget(buildApp(menuOf(haptics: true)));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));

      final gesture = await tester.startGesture(source.center);
      await tester.pump();
      await advance(tester, holdMs - 1);
      expect(haptics.ticks, 0, reason: 'nothing before the hold is up');
      await advance(tester, 1);
      expect(haptics.ticks, 1, reason: 'one as the hold commits');
      await advance(tester, 300);
      await gesture.up();
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(haptics.ticks, 1);

      // A right click has no hold to pay off.
      final click = await tester.startGesture(
        source.center,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await settle(tester);
      expect(haptics.ticks, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
    });

    testWidgets('a lift without haptics asks for nothing', (tester) async {
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final gesture = await holdOpen(tester);
      await gesture.up();
      await settle(tester);
      expect(haptics.requests, isEmpty);
    });
  });

  group('reduced motion', () {
    testWidgets('the lifted state is shown, without the animation into it', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf(), reduceMotion: true));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await tester.startGesture(source.center);
      await tester.pump();

      await advance(tester, 149);
      expect(
        liftLayer,
        findsNothing,
        reason: 'the delay is a wait, not motion',
      );
      await advance(tester, 2);
      final up = lookOf(tester, source)!;
      expect(up.scale, closeTo(1.04, 1e-6), reason: 'it arrives at once');
      expect(up.dim, closeTo(0.2, 0.004));

      // Let go before the hold is up: back at once as well.
      await gesture.up();
      await tester.pump();
      expect(liftLayer, findsNothing);
      expect(originalHidden(tester), isFalse);
    });

    testWidgets('the close is a jump too: the copy goes with the panel', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf(), reduceMotion: true));
      await settle(tester);
      final gesture = await holdOpen(tester);
      await gesture.up();
      await tester.pump();
      expect(liftLayer, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await settle(tester);
      expect(liftLayer, findsNothing);
      expect(find.byType(Menu), findsNothing);
      expect(originalHidden(tester), isFalse);
    });
  });

  group('places', () {
    testWidgets('a menu taller than the viewport folds like any other', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildApp(menuOf(rows: 40)));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final click = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 500);
      final panel = tester.getRect(find.byType(Menu));
      expect(panel.height, lessThanOrEqualTo(400));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await advance(tester, closeMs ~/ 2);
      final now = tester.getRect(find.byType(Menu));
      final scale = now.width / panel.width;
      expect(scale, lessThan(1));
      expect(scale, greaterThan(0.3));
      final centre = panel.center;
      final pivot = Offset(
        centre.dx.clamp(source.left, source.right),
        centre.dy.clamp(source.top, source.bottom),
      );
      expect(
        now.left,
        closeTo(pivot.dx + (panel.left - pivot.dx) * scale, 1e-4),
      );
      expect(
        now.top,
        closeTo(pivot.dy + (panel.top - pivot.dy) * scale, 1e-4),
      );
      await settle(tester);
      expect(liftLayer, findsNothing);
    });

    testWidgets('a source that scrolls takes the copy with it', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        buildApp(
          SizedBox(
            height: 600,
            child: ListView(
              controller: scroll,
              children: [
                const SizedBox(height: 100),
                menuOf(),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final click = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 500);

      scroll.jumpTo(60);
      await tester.pump();
      final original = tester.getRect(originalRegion);
      final copy = tester.getRect(copyRegion);
      expect(original.top, closeTo(source.top - 60, 1e-6));
      expect(copy.center.dx, closeTo(original.center.dx, 1e-6));
      expect(
        copy.center.dy,
        closeTo(original.center.dy, 1e-6),
        reason: 'the copy follows the original through the scroll',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(liftLayer, findsNothing);
    });
  });

  group('nothing is left behind', () {
    int overlayChildren(WidgetTester tester) {
      var count = 0;
      tester
          .renderObject<RenderObject>(find.byType(Overlay).first)
          .visitChildren((_) => count++);

      return count;
    }

    testWidgets('a full cycle leaves the overlay as it found it', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final before = overlayChildren(tester);

      final gesture = await holdOpen(tester);
      expect(overlayChildren(tester), greaterThan(before));
      await gesture.up();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);

      expect(overlayChildren(tester), before);
      expect(liftLayer, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing the widget with the lift up puts everything away', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final before = overlayChildren(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await tester.startGesture(source.center);
      await tester.pump();
      await advance(tester, 300);
      expect(liftLayer, findsOneWidget);

      await tester.pumpWidget(buildApp(const SizedBox()));
      await tester.pump();
      expect(liftLayer, findsNothing);
      expect(overlayChildren(tester), before);
      await gesture.up();
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'disposing the widget with the menu open puts everything away',
      (
        tester,
      ) async {
        await tester.pumpWidget(buildApp(menuOf()));
        await settle(tester);
        final before = overlayChildren(tester);
        final gesture = await holdOpen(tester);
        await gesture.up();
        await tester.pump();
        expect(find.byType(Menu), findsOneWidget);

        await tester.pumpWidget(buildApp(const SizedBox()));
        await settle(tester);
        expect(find.byType(Menu), findsNothing);
        expect(liftLayer, findsNothing);
        expect(overlayChildren(tester), before);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'opening again while the last close is still folding takes over',
      (
        tester,
      ) async {
        await tester.pumpWidget(buildApp(menuOf()));
        await settle(tester);
        final source = tester.getRect(find.byKey(regionKey));
        Future<void> click() async {
          final g = await tester.startGesture(
            source.topLeft + const Offset(60, 50),
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryButton,
          );
          await g.up();
          await tester.pump();
        }

        await click();
        await advance(tester, 500);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await advance(tester, 30);
        expect(liftLayer, findsOneWidget, reason: 'still folding');

        await click();
        await advance(tester, 500);
        expect(tester.takeException(), isNull);
        expect(find.byType(Menu), findsOneWidget);
        expect(liftLayer, findsOneWidget);
        expect(originalHidden(tester), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        expect(find.byType(Menu), findsNothing);
        expect(liftLayer, findsNothing);
        expect(originalHidden(tester), isFalse);
      },
    );
  });

  group('the option', () {
    testWidgets('a press on a disabled menu lifts nothing', (tester) async {
      await tester.pumpWidget(
        buildApp(
          ContextMenu(
            items: itemsOf(),
            liftChild: true,
            enabled: false,
            child: region(),
          ),
        ),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await tester.startGesture(source.center);
      await tester.pump();
      await advance(tester, holdMs + 200);

      expect(liftLayer, findsNothing);
      expect(find.byType(Menu), findsNothing);
      expect(originalHidden(tester), isFalse);
      await gesture.up();
      await settle(tester);
    });

    testWidgets(
      'turning it off with a lift up takes the copy away at once and the menu '
      'closes plainly',
      (
        tester,
      ) async {
        // No autofocus in the child: remounting it would hand focus to the
        // page and take it from the menu, which is not what is tested here.
        Widget app({required bool lift}) => buildApp(
          menuOf(
            lift: lift,
            child: const SizedBox(
              key: regionKey,
              width: regionWidth,
              height: regionHeight,
            ),
          ),
        );
        await tester.pumpWidget(app(lift: true));
        await settle(tester);
        final gesture = await holdOpen(tester);
        await gesture.up();
        await tester.pump();
        expect(liftLayer, findsOneWidget);

        await tester.pumpWidget(app(lift: false));
        await tester.pump();
        // Nothing wraps the original any more, so a copy left standing would
        // show the child twice.
        expect(liftLayer, findsNothing);
        expect(find.byKey(regionKey), findsOneWidget);
        expect(
          find.byType(Menu),
          findsOneWidget,
          reason: 'the menu stays open',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        expect(find.byType(Menu), findsNothing);
        expect(liftLayer, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'turning it off while a touch is held lets the touch end quietly',
      (
        tester,
      ) async {
        Widget app({required bool lift}) => buildApp(menuOf(lift: lift));
        await tester.pumpWidget(app(lift: true));
        await settle(tester);
        final source = tester.getRect(find.byKey(regionKey));
        final gesture = await tester.startGesture(source.center);
        await tester.pump();
        await advance(tester, 300);
        expect(liftLayer, findsOneWidget);

        await tester.pumpWidget(app(lift: false));
        await tester.pump();
        expect(liftLayer, findsNothing);
        expect(originalHidden(tester), isFalse);
        await gesture.up();
        await settle(tester);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('an assistive long press lifts together with the menu', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildApp(
          menuOf(
            haptics: true,
            child: Semantics(
              label: 'source',
              child: const SizedBox(
                key: regionKey,
                width: regionWidth,
                height: regionHeight,
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      final haptics = _Haptics(tester);
      addTearDown(haptics.dispose);

      tester.semantics.longPress(find.semantics.byLabel('source'));
      await tester.pump();
      await advance(tester, 400);

      expect(find.byType(Menu), findsOneWidget);
      expect(liftLayer, findsOneWidget, reason: 'no touch, so no hold to wait');
      expect(originalHidden(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(liftLayer, findsNothing);
      handle.dispose();
    });

    testWidgets('the copy lies under the menu however the menu was opened', (
      tester,
    ) async {
      // The order of the overlay's children is the order they are painted in,
      // bottom first, so it is read off the tree: the copy's layer must come
      // before the menu for the menu to lie over it. A hit test cannot say -
      // the copy takes no pointer, so a tap passes through it either way.
      List<String> stack() {
        final seen = <String>[];
        void visit(Element element) {
          final widget = element.widget;
          if (widget is ContextMenuLiftLayer) seen.add('copy');
          if (widget is Menu) seen.add('menu');
          element.visitChildren(visit);
        }

        tester.binding.rootElement!.visitChildren(visit);

        return seen;
      }

      final controller = PopoverController();
      await tester.pumpWidget(buildApp(menuOf(controller: controller)));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));

      for (final (via, open) in <(String, Future<void> Function())>[
        (
          'a right click',
          () async {
            final click = await tester.startGesture(
              source.topLeft + const Offset(60, 50),
              kind: PointerDeviceKind.mouse,
              buttons: kSecondaryButton,
            );
            await click.up();
          },
        ),
        ('the controller', () async => controller.show()),
        (
          'a held touch',
          () async {
            final held = await holdOpen(tester);
            await held.up();
          },
        ),
      ]) {
        await open();
        await tester.pump();
        await advance(tester, 400);
        expect(
          stack(),
          ['copy', 'menu'],
          reason: '$via: the copy is below the menu',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
        expect(liftLayer, findsNothing, reason: '$via: put away');
      }
    });

    testWidgets('a tap on the copy is a tap outside the menu', (tester) async {
      await tester.pumpWidget(buildApp(menuOf()));
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await holdOpen(tester);
      await gesture.up();
      await tester.pump();
      expect(find.byType(Menu), findsOneWidget);

      // Inside the region, away from the panel: the copy is under the barrier.
      await tester.tapAt(source.bottomLeft + const Offset(20, -20));
      await settle(tester);
      expect(find.byType(Menu), findsNothing);
      expect(liftLayer, findsNothing);
    });
  });

  // --- a style that states other numbers --------------------------------

  group('a style that states other numbers', () {
    final other = restyled['numbers']! as Map<String, Object?>;
    final traces = _list(restyled['traces']);
    final otherRadius = _num(other['radius']);

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
          liftRadius: CoreBorderRadius.all(otherRadius),
          retractScale: _num(other['retractScale']),
        );

    Duration riseOf(Map<String, Object?> trace) =>
        Duration(milliseconds: (trace['durationMs']! as num).toInt());

    /// The corners of the box the copy's cast is cast from, right now.
    BorderRadius castRadius(WidgetTester tester) => tester
        .widget<InjectedCast>(
          find.descendant(of: follower, matching: find.byType(InjectedCast)),
        )
        .borderRadius;

    /// Opens with a right click and lets the lift come to rest.
    Future<void> openAndRest(WidgetTester tester) async {
      final source = tester.getRect(find.byKey(regionKey));
      final click = await tester.startGesture(
        source.topLeft + const Offset(60, 50),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await click.up();
      await tester.pump();
      await advance(tester, 500);
    }

    test('states other numbers than the defaults, in every field', () {
      expect(_num(other['liftScale']), isNot(_num(numbers['liftScale'])));
      expect(_num(other['dimOpacity']), isNot(_num(numbers['dimOpacity'])));
      expect(_num(other['retractScale']), isNot(_num(numbers['retractScale'])));
      expect(otherRadius, isNot(_num(numbers['radius'])));
      expect(_list(other['cast']), isNot(_list(numbers['cast'])));
    });

    for (final trace in traces) {
      testWidgets(
        "${trace['name']} - the menu's own style",
        (tester) => replayTrace(
          tester,
          trace,
          style: styleWith(rise: riseOf(trace)),
        ),
      );
      testWidgets(
        "${trace['name']} - the theme's style",
        (tester) => replayTrace(
          tester,
          trace,
          theme: CoreContextMenuTheme(style: styleWith(rise: riseOf(trace))),
        ),
      );
    }

    testWidgets("the corners of the cast box are the style's", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          menuOf(style: styleWith(rise: const Duration(milliseconds: 200))),
        ),
      );
      await settle(tester);
      await openAndRest(tester);
      expect(castRadius(tester), BorderRadius.circular(otherRadius));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
    });

    testWidgets("and the theme's, for every menu that states none", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          menuOf(),
          contextMenuTheme: CoreContextMenuTheme(
            style: styleWith(rise: const Duration(milliseconds: 200)),
          ),
        ),
      );
      await settle(tester);
      await openAndRest(tester);
      expect(castRadius(tester), BorderRadius.circular(otherRadius));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
    });

    testWidgets("the menu's own style beats the theme, field by field", (
      tester,
    ) async {
      // The theme states the whole restyled look; the menu overrides only the
      // size. The size is the menu's, the rest is still the theme's.
      await tester.pumpWidget(
        buildApp(
          menuOf(style: const CoreContextMenuStyle(liftScale: 1.2)),
          contextMenuTheme: CoreContextMenuTheme(
            style: styleWith(rise: const Duration(milliseconds: 200)),
          ),
        ),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      await openAndRest(tester);

      final look = lookOf(tester, source)!;
      expect(look.scale, closeTo(1.2, 1e-6), reason: "the menu's own size");
      expect(look.dim, closeTo(_num(other['dimOpacity']), 0.004));
      final cast = _list(other['cast']).single;
      expect(look.cast.single.offset.dy, closeTo(_num(cast['offsetY']), 1e-6));
      expect(look.cast.single.color.a, closeTo(_num(cast['opacity']), 0.004));
      expect(castRadius(tester), BorderRadius.circular(otherRadius));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
    });

    testWidgets('a style that states one number leaves the others default', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(menuOf(style: const CoreContextMenuStyle(liftScale: 1.2))),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      await openAndRest(tester);

      final look = lookOf(tester, source)!;
      expect(look.scale, closeTo(1.2, 1e-6));
      expect(look.dim, closeTo(_num(numbers['dimOpacity']), 0.004));
      final cast = _list(numbers['cast']).single;
      expect(look.cast.single.offset.dy, closeTo(_num(cast['offsetY']), 1e-6));
      expect(
        castRadius(tester),
        BorderRadius.circular(_num(numbers['radius'])),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
    });

    testWidgets('a style that states the defaults changes nothing', (
      tester,
    ) async {
      // Every trace of the table, on a menu that states the design-system
      // defaults explicitly: the same pictures as on one that states nothing.
      const stated = CoreContextMenuStyle(
        liftScale: CoreContextMenuStyle.defaultLiftScale,
        liftDuration: CoreContextMenuStyle.defaultLiftDuration,
        liftDimOpacity: CoreContextMenuStyle.defaultLiftDimOpacity,
        liftCast: CoreContextMenuStyle.defaultLiftCast,
        liftRadius: CoreContextMenuStyle.defaultLiftRadius,
        retractScale: CoreContextMenuStyle.defaultRetractScale,
      );
      for (final trace in _list(doc['traces'])) {
        final platforms = (trace['platforms'] as List?)?.cast<String>();
        if (platforms != null && !platforms.contains('flutter')) continue;
        await replayTrace(tester, trace, style: stated);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('the panel folds to the size the style states', (tester) async {
      await tester.pumpWidget(
        buildApp(
          menuOf(style: styleWith(rise: const Duration(milliseconds: 200))),
        ),
      );
      await settle(tester);
      await openAndRest(tester);
      final panel = tester.getRect(find.byType(Menu));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      var at = 0;
      for (final row in _list(restyled['retractCurve'])) {
        final ms = (_num(row['fraction']) * closeMs).round();
        if (ms >= closeMs) break; // the end is the panel gone
        await advance(tester, ms - at);
        at = ms;
        final now = tester.getRect(find.byType(Menu));
        expect(
          now.width / panel.width,
          closeTo(_num(row['scale']), 1e-6),
          reason: '${(_num(row['fraction']) * 100).round()}% through the close',
        );
      }
      await settle(tester);
      expect(find.byType(Menu), findsNothing);
    });

    testWidgets('reduced motion still makes the rise a jump', (tester) async {
      // 400 ms is transition motion (at most `transitionCeilingMs`), so the
      // policy collapses it whatever the style states.
      await tester.pumpWidget(
        buildApp(
          menuOf(style: styleWith(rise: const Duration(milliseconds: 400))),
          reduceMotion: true,
        ),
      );
      await settle(tester);
      final source = tester.getRect(find.byKey(regionKey));
      final gesture = await tester.startGesture(source.center);
      await tester.pump();

      await advance(tester, 149);
      expect(liftLayer, findsNothing, reason: 'the delay is a wait');
      await advance(tester, 2);
      final up = lookOf(tester, source)!;
      expect(up.scale, closeTo(_num(other['liftScale']), 1e-6));
      expect(up.dim, closeTo(_num(other['dimOpacity']), 0.004));

      await gesture.up();
      await tester.pump();
      expect(liftLayer, findsNothing);
    });
  });

  group("the app's size scaling", () {
    testWidgets('the corner of the box the cast is cast from follows it', (
      tester,
    ) async {
      Future<({ResolvedContextMenu menu, ResolvedContextMenuLift frame})>
      resolveAt(AdaptiveScaling scaling) async {
        ResolvedContextMenu? menu;
        ResolvedContextMenuLift? frame;
        // A second mount reuses the first overlay's tree, so unmount first.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) {
                menu = resolveContextMenu(context);
                frame = resolveContextMenuLift(
                  context,
                  menu: menu!,
                  progress: 1,
                );

                return const SizedBox.shrink();
              },
            ),
            theme: scaling.scale(ThemeData.fromCore(CoreThemePresets.light)),
          ),
        );
        expect(frame, isNotNull, reason: 'the builder never ran');

        return (menu: menu!, frame: frame!);
      }

      final rest = await resolveAt(AdaptiveScaling.desktop);
      final phone = await resolveAt(const AdaptiveScaling(1.25));

      expect(
        rest.frame.borderRadius,
        BorderRadius.circular(CoreRadiusRole.surface),
      );
      expect(
        phone.frame.borderRadius,
        BorderRadius.circular(CoreRadiusRole.surface * 1.25),
        reason: 'a card the copy hugs scales its corner; the cast box must too',
      );
      // The cast is not scaled: the Web box-shadow never scales.
      expect(phone.frame.shadows, rest.frame.shadows);
    });
  });

  group('in the dark', () {
    testWidgets(
      'the cast is the one the style states, strengthened for the dark',
      (
        tester,
      ) async {
        const semantic = CouiSemanticColors.from(CouiColorPresets.source);
        final dark = applySurfaceStyle(
          ThemeData(colorScheme: semantic.dark.resolved(.dark)),
          surfaceStyle: .defaultStyle,
          highContrast: false,
        );
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: dark,
              child: material.Scaffold(body: material.Center(child: menuOf())),
            ),
          ),
        );
        await settle(tester);
        final source = tester.getRect(find.byKey(regionKey));
        final click = await tester.startGesture(
          source.topLeft + const Offset(60, 50),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await click.up();
        await tester.pump();
        await advance(tester, 500);

        final cast = tester
            .widget<InjectedCast>(
              find.descendant(
                of: follower,
                matching: find.byType(InjectedCast),
              ),
            )
            .shadows;
        final rest = _list(numbers['cast']).single;
        final base = dark.colorScheme
            .resolve(const CoreColor.token(CoreColors.shadow))
            .toValue();
        const strength = CoreShadow.darkStrength;
        expect(cast, hasLength(1));
        expect(cast.single.offset.dy, closeTo(_num(rest['offsetY']), 1e-6));
        expect(
          cast.single.color.a,
          closeTo(
            (base.a * _num(rest['opacity']) * strength).clamp(0, 1),
            0.004,
          ),
          reason: 'the dark strengthens the cast as it does every other',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle(tester);
      },
    );
  });

  group('the engine hands the leaving to the host', () {
    testWidgets('a panel the host paints keeps its size and opacity while the '
        'engine counts the close down', (tester) async {
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => const PopoverOverlayHandler().show<void>(
                alignment: Alignment.topLeft,
                anchorAlignment: Alignment.topLeft,
                context: context,
                hostPaintsClose: true,
                dismissDuration: const Duration(milliseconds: 100),
                builder: (_) => const SizedBox(
                  key: ValueKey('panel'),
                  width: 100,
                  height: 60,
                ),
              ),
              child: const ColoredBox(
                key: regionKey,
                color: Color(0x00000000),
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(regionKey));
      await settle(tester);
      expect(find.byKey(const ValueKey('panel')), findsOneWidget);
      final open = tester.getSize(find.byKey(const ValueKey('panel')));

      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('panel')), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('panel'))), open);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('panel')),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1, reason: 'the engine does not fade it');

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(find.byKey(const ValueKey('panel')), findsNothing);
    });
  });
}
