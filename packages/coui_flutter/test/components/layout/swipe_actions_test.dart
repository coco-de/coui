import 'dart:ui' show SemanticsAction, Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsNode;
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const double _kRowWidth = 400;
const double _kRowHeight = 72;
const Key _kRowKey = Key('row');

/// A display's frame: how often a moving pointer is reported.
const Duration _kFrame = Duration(milliseconds: 16);

/// The width of a platter of [count] default cells — the figure the table
/// shared with the Web seat states (72 · 132 · 192).
double _extent(int count) => CoreSwipeActionsStyle.extentFor(
  count,
  actionWidth: CoreSwipeActionsStyle.defaultActionWidth,
  actionSpacing: CoreSwipeActionsStyle.defaultActionSpacing,
  platterInset: CoreSwipeActionsStyle.defaultPlatterInset,
);

/// [count] actions tagged `<tag>0`, `<tag>1`, … Each draws a keyed glyph (so a
/// test can find where its cell is), and each records its tag in [log] when
/// run.
List<CoreSwipeAction<Widget>> _actions(
  String tag,
  int count, {
  List<String>? log,
  Set<int> disabled = const {},
  Set<int> destructive = const {},
}) => [
  for (var i = 0; i < count; i++)
    CoreSwipeAction<Widget>(
      label: '$tag$i',
      icon: Icon(LucideIcons.x, key: ValueKey('$tag$i')),
      variant: destructive.contains(i)
          ? CoreSwipeActionVariant.destructive
          : CoreSwipeActionVariant.defaultVariant,
      enabled: !disabled.contains(i),
      onPressed: () => log?.add('$tag$i'),
    ),
];

/// The row child: a plain box that fills the row.
Widget _plainRow({Key key = _kRowKey, VoidCallback? onTap}) {
  final box = ColoredBox(
    key: key,
    color: const Color(0xFFEEEEEE),
    child: const SizedBox.expand(),
  );

  return onTap == null ? box : GestureDetector(onTap: onTap, child: box);
}

/// Stands in for the scroller a row lives in. A drag recogniser with nothing
/// to compete with wins the arena the moment the pointer goes down, before any
/// slop — a row in a list never does, and the pull it is held to is the one
/// that arms after the slop.
Widget _scroller(Widget child) => GestureDetector(
  behavior: HitTestBehavior.translucent,
  onVerticalDragUpdate: (_) {},
  child: child,
);

/// Pumps [child] in the test app, replacing whatever an earlier pump mounted.
/// The app shell builds its overlay entry once, so pumping it a second time
/// would keep showing the first child.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  CoreComponentTheme? componentTheme,
  CoreDensity density = CoreDensity.defaultDensity,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    child,
    theme: theme,
    componentTheme: componentTheme,
    density: density,
    textDirection: textDirection,
    disableAnimations: disableAnimations,
  );
}

/// Mounts [first] and returns the notifier that swaps it for another widget
/// under the same elements, so a test can change what a live row is given.
Future<ValueNotifier<Widget>> _pumpLive(
  WidgetTester tester,
  Widget first,
) async {
  final content = ValueNotifier<Widget>(first);
  addTearDown(content.dispose);
  await pumpTestApp(
    tester,
    ValueListenableBuilder<Widget>(
      valueListenable: content,
      builder: (context, widget, _) => widget,
    ),
  );

  return content;
}

/// A row child with state, to see whether opening and closing rebuilds it.
class _Probe extends StatefulWidget {
  const _Probe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => _plainRow();
}

/// One row of the table's size.
Widget _row({
  Key? key,
  List<String>? log,
  int leading = 0,
  int trailing = 2,
  Set<int> disabledLeading = const {},
  Set<int> disabledTrailing = const {},
  Set<int> destructiveTrailing = const {},
  bool allowsFullSwipe = true,
  double fullSwipeThreshold =
      CoreSwipeActionsContract.defaultFullSwipeThreshold,
  bool showLabels = true,
  bool? enabled,
  CoreSwipeActionsStyle? style,
  Widget? child,
}) => _scroller(
  SizedBox(
    width: _kRowWidth,
    height: _kRowHeight,
    child: SwipeActions(
      key: key,
      leadingActions: _actions(
        'L',
        leading,
        log: log,
        disabled: disabledLeading,
      ),
      trailingActions: _actions(
        'T',
        trailing,
        log: log,
        disabled: disabledTrailing,
        destructive: destructiveTrailing,
      ),
      allowsFullSwipe: allowsFullSwipe,
      fullSwipeThreshold: fullSwipeThreshold,
      showLabels: showLabels,
      enabled: enabled,
      swipeActionsStyle: style,
      child: child ?? _plainRow(),
    ),
  ),
);

Offset _originOf(WidgetTester tester, [Finder? finder]) =>
    tester.getTopLeft(finder ?? find.byType(SwipeActions).first);

/// How far the row has moved from its resting box (physical px, +right).
double _offsetOf(WidgetTester tester, Offset origin, [Key key = _kRowKey]) =>
    tester.getTopLeft(find.byKey(key)).dx - origin.dx;

/// Presses at [start] and moves [offset] over [duration] — one move per
/// frame, each stamped with the time it happened — and returns the gesture
/// still held, with the clock at the last move.
///
/// The tester's clock moves with the stamps (a pump between moves), because
/// Flutter's velocity tracker asks the clock, not only the stamps, whether the
/// pointer has stopped.
Future<({TestGesture gesture, Duration clock})> _pressAndStroke(
  WidgetTester tester,
  Offset start,
  Offset offset,
  Duration duration, {
  Duration frame = _kFrame,
}) async {
  final gesture = await tester.startGesture(start);
  final steps = (duration.inMicroseconds / frame.inMicroseconds).ceil();
  final step = Duration(
    microseconds: (duration.inMicroseconds / steps).round(),
  );
  var clock = Duration.zero;
  for (var i = 1; i <= steps; i++) {
    clock += step;
    await gesture.moveTo(start + offset * (i / steps), timeStamp: clock);
    await tester.pump(step);
  }

  return (gesture: gesture, clock: clock);
}

/// Lifts the held `stroke` [hold] after its last move.
Future<void> _lift(
  WidgetTester tester,
  ({TestGesture gesture, Duration clock}) stroke, {
  Duration hold = Duration.zero,
}) async {
  if (hold > Duration.zero) await tester.pump(hold);
  await stroke.gesture.up(timeStamp: stroke.clock + hold);
}

/// A slow pull: 100 px/s, far under a flick.
Future<({TestGesture gesture, Duration clock})> _slowPull(
  WidgetTester tester,
  Offset start,
  double dx,
) => _pressAndStroke(
  tester,
  start,
  Offset(dx, 0),
  Duration(milliseconds: (dx.abs() * 10).round()),
);

/// Presses at [start] and pulls the row [travel] px (signed, physical) slowly:
/// the pointer first goes 20 px — past the slop, which is forgiven, so the row
/// has not moved yet — and then [travel] more, at 100 px/s, or over [over]
/// when that is given. The row ends [travel] px from where it began, however
/// fast it got there.
Future<({TestGesture gesture, Duration clock})> _pull(
  WidgetTester tester,
  Offset start,
  double travel, {
  Duration? over,
}) async {
  const arm = 20.0;
  final sign = travel.sign;
  final gesture = await tester.startGesture(start);
  var clock = const Duration(milliseconds: 100);
  await tester.pump(clock);
  await gesture.moveTo(start + Offset(sign * arm, 0), timeStamp: clock);
  await tester.pump(_kFrame);
  clock += _kFrame;

  final duration = over ?? Duration(milliseconds: (travel.abs() * 10).round());
  final steps = (duration.inMicroseconds / _kFrame.inMicroseconds).ceil();
  final step = Duration(
    microseconds: (duration.inMicroseconds / steps).round(),
  );
  for (var i = 1; i <= steps; i++) {
    clock += step;
    await gesture.moveTo(
      start + Offset(sign * (arm + travel.abs() * i / steps), 0),
      timeStamp: clock,
    );
    await tester.pump(step);
  }
  await tester.pump();

  return (gesture: gesture, clock: clock);
}

/// Pulls the row open by hand and waits for it to rest. [dx] is the physical
/// travel (the slop is forgiven, so it is the travel of the row plus 18).
Future<void> _openBy(WidgetTester tester, Offset origin, double dx) async {
  final start = origin + Offset(dx < 0 ? 300 : 100, _kRowHeight / 2);
  final stroke = await _slowPull(tester, start, dx);
  await _lift(tester, stroke);
  await tester.pumpAndSettle();
}

/// Opens the trailing platter of an LTR row of [count] actions.
Future<void> _openTrailing(
  WidgetTester tester,
  Offset origin, {
  int count = 2,
}) => _openBy(tester, origin, -(_extent(count) + 40));

/// Opens the leading platter of an LTR row of [count] actions.
Future<void> _openLeading(
  WidgetTester tester,
  Offset origin, {
  int count = 1,
}) => _openBy(tester, origin, _extent(count) + 40);

/// The labels of the custom semantics actions a node offers.
Set<String> _customLabels(SemanticsNode node) => {
  for (final id in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
    CustomSemanticsAction.getAction(id)!.label!,
};

/// The custom semantics actions the row declares, in the order it declares
/// them — the order a screen reader's action menu is built in.
///
/// A node cannot be asked for this order for a label that was used before:
/// it lists the ids of its actions ascending, and an id is handed out the
/// first time an action is seen anywhere in the process, so a reused label
/// comes out where it first appeared. The declaration is read where it is
/// made.
List<String> _declaredActionOrder(WidgetTester tester) {
  final declaring = tester.widget<Semantics>(
    find.descendant(
      of: find.byType(SwipeActions),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.customSemanticsActions != null,
      ),
    ),
  );

  return [
    for (final action in declaring.properties.customSemanticsActions!.keys)
      action.label!,
  ];
}

/// Every node of the semantics tree that is a button.
List<SemanticsNode> _buttonNodes(WidgetTester tester) {
  final found = <SemanticsNode>[];
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isButton) found.add(node);
    node.visitChildren((child) {
      walk(child);

      return true;
    });
  }

  // The tree is walked from its root, which is found from the row.
  var root = tester.getSemantics(find.byType(SwipeActions).first);
  while (root.parent != null) {
    root = root.parent!;
  }
  walk(root);

  return found;
}

Set<String> _buttonLabels(WidgetTester tester) => {
  for (final node in _buttonNodes(tester)) node.getSemanticsData().label,
};

void _runCustomAction(SemanticsNode node, String label) =>
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: label)),
    );

Finder _cellButton(String tag) => find.ancestor(
  of: find.byKey(ValueKey(tag)),
  matching: find.byType(Button),
);

double _centerX(WidgetTester tester, String tag) =>
    tester.getCenter(find.byKey(ValueKey(tag))).dx;

/// The strip that holds [tag]'s cell: the one the row uncovers.
Finder _stripOf(String tag) => find.ancestor(
  of: find.byKey(ValueKey(tag)),
  matching: find.byType(PositionedDirectional),
);

/// How wide the strip holding [tag] is drawn (px). A closed side keeps its
/// cells laid out, clipped to a strip of no width.
double _stripWidth(WidgetTester tester, String tag) =>
    tester.getSize(_stripOf(tag)).width;

/// What a strip holds: the strip's content under the focus and semantics
/// plumbing that surrounds it.
Widget _stripChild(PositionedDirectional strip) {
  var current = strip.child;
  while (current is FocusTraversalOrder ||
      current is Focus ||
      current is ExcludeSemantics) {
    current = switch (current) {
      final FocusTraversalOrder order => order.child,
      final Focus focus => focus.child,
      final ExcludeSemantics exclude => exclude.child!,
      _ => current,
    };
  }

  return current;
}

/// Whether the platter of [tag]'s side is closed: drawn at no width, so none
/// of its cells can be seen or pressed.
bool _isClipped(WidgetTester tester, String tag) =>
    _stripWidth(tester, tag) == 0;

/// A row child a keyboard can stop on, to show where the row's own content sits
/// in the order.
Widget _focusableRow() => Focus(debugLabel: 'content', child: _plainRow());

/// A stop before and after a row, so a walk has somewhere to begin and end.
Widget _walk(Widget row) => Shortcuts(
  // The bare test shell has no `Tab`: a real app gets these from its app
  // widget, so they are what the keyboard tests run under.
  shortcuts: WidgetsApp.defaultShortcuts,
  child: Actions(
    actions: WidgetsApp.defaultActions,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Focus(
          debugLabel: 'start',
          autofocus: true,
          child: SizedBox(width: 20, height: 20),
        ),
        row,
        const Focus(
          debugLabel: 'end',
          child: SizedBox(width: 20, height: 20),
        ),
      ],
    ),
  ),
);

const List<String> _kTags = ['L0', 'L1', 'L2', 'T0', 'T1', 'T2'];

/// What has focus: the tag of an action whose button does, otherwise the
/// label of the focused node (`start`, `content`, `end`, or `SwipeActions` for
/// the row itself).
String? _focused(WidgetTester tester) {
  final primary = FocusManager.instance.primaryFocus;
  if (primary == null) return null;
  for (final tag in _kTags) {
    final glyph = find.byKey(ValueKey(tag));
    if (glyph.evaluate().isEmpty) continue;
    final node = Focus.maybeOf(tester.element(glyph), createDependency: false);
    if (identical(node, primary)) return tag;
  }

  return primary.debugLabel;
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

/// Presses `Tab` [count] times and says what had focus after each press.
Future<List<String?>> _tabs(
  WidgetTester tester,
  int count, {
  bool shift = false,
}) async {
  final seen = <String?>[];
  for (var i = 0; i < count; i++) {
    await _key(tester, LogicalKeyboardKey.tab, shift: shift);
    seen.add(_focused(tester));
  }

  return seen;
}

void main() {
  group('SwipeActions at rest', () {
    testWidgets('draws only the row: the actions are clipped to nothing', (
      tester,
    ) async {
      await _pump(tester, _row());

      expect(tester.getSize(find.byType(SwipeActions)), const Size(400, 72));
      expect(tester.getSize(find.byKey(_kRowKey)), const Size(400, 72));
      // The actions are laid out, so a keyboard can reach them, but a strip of
      // no width shows none of them and nothing of them can be pressed.
      expect(find.byType(Button), findsNWidgets(2));
      expect(_isClipped(tester, 'T0'), isTrue);
      expect(find.byType(Button).hitTestable(), findsNothing);
    });

    testWidgets('a closed row paints nothing of its actions, even under a '
        'child that paints nothing', (tester) async {
      // The actions are laid out for a keyboard. A row whose child is
      // transparent would show them through it if a closed side were drawn.
      final boundary = GlobalKey();
      await _pump(
        tester,
        RepaintBoundary(
          key: boundary,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: _row(leading: 1, child: const SizedBox.expand()),
          ),
        ),
      );
      expect(find.byType(Button), findsNWidgets(3));

      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await render.toImage();
        final data = await image.toByteData();
        image.dispose();

        return data!.buffer.asUint8List();
      });

      expect(bytes, isNotNull);
      expect(
        bytes!.every((byte) => byte == 0xFF),
        isTrue,
        reason: 'every pixel is the white behind the row',
      );
    });

    testWidgets('the row keeps the constraints it was given', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 250,
          height: 90,
          child: SwipeActions(
            trailingActions: _actions('T', 1),
            child: _plainRow(),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(_kRowKey)), const Size(250, 90));
    });

    testWidgets('a tap reaches the row child', (tester) async {
      var taps = 0;
      await _pump(tester, _row(child: _plainRow(onTap: () => taps++)));

      await tester.tap(find.byKey(_kRowKey));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets(
      'the row child keeps its state while the platters come and go',
      (
        tester,
      ) async {
        var inits = 0;
        await _pump(tester, _row(child: _Probe(onInit: () => inits++)));
        final origin = _originOf(tester);
        expect(inits, 1);

        await _openTrailing(tester, origin);
        expect(_isClipped(tester, 'T0'), isFalse);
        await tester.tapAt(origin + const Offset(100, 36));
        await tester.pumpAndSettle();
        expect(_isClipped(tester, 'T0'), isTrue);

        expect(inits, 1, reason: 'the child was built once, not per pose');
      },
    );

    test('the framework arms a drag at the distance the Contract names', () {
      expect(kTouchSlop, CoreSwipeActionsContract.defaultDragSlop);
    });
  });

  group('SwipeActions layout', () {
    testWidgets('the outermost action is the first, at the screen edge (LTR)', (
      tester,
    ) async {
      await _pump(tester, _row(leading: 3, trailing: 3));
      final origin = _originOf(tester);

      await _openTrailing(tester, origin, count: 3);
      expect(_offsetOf(tester, origin), -_extent(3));
      const cell = 48.0;
      const gap = 12.0;
      const inset = 12.0;
      // From the right edge inward: T0 outermost, then T1, then T2.
      for (var i = 0; i < 3; i++) {
        expect(
          _centerX(tester, 'T$i') - origin.dx,
          closeTo(_kRowWidth - inset - cell / 2 - i * (cell + gap), 1e-6),
          reason: 'T$i sits ${i + 1}th from the right edge',
        );
      }

      // Closing the trailing side and opening the leading one: L0 outermost,
      // at the left edge.
      await tester.tapAt(origin + const Offset(100, 36));
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), 0);
      await _openLeading(tester, origin, count: 3);
      for (var i = 0; i < 3; i++) {
        expect(
          _centerX(tester, 'L$i') - origin.dx,
          closeTo(inset + cell / 2 + i * (cell + gap), 1e-6),
          reason: 'L$i sits ${i + 1}th from the left edge',
        );
      }
    });

    testWidgets('mirrored under right-to-left', (tester) async {
      await _pump(
        tester,
        _row(leading: 2),
        textDirection: TextDirection.rtl,
      );
      final origin = _originOf(tester);
      const cell = 48.0;
      const gap = 12.0;
      const inset = 12.0;

      // The leading platter is on the right; it opens by pulling left.
      await _openTrailing(tester, origin);
      expect(_offsetOf(tester, origin), -_extent(2));
      for (var i = 0; i < 2; i++) {
        expect(
          _centerX(tester, 'L$i') - origin.dx,
          closeTo(_kRowWidth - inset - cell / 2 - i * (cell + gap), 1e-6),
          reason: 'L$i is outermost at the right edge in RTL',
        );
      }

      await tester.tapAt(origin + const Offset(100, 36));
      await tester.pumpAndSettle();

      // The trailing platter is on the left; it opens by pulling right.
      await _openLeading(tester, origin, count: 2);
      expect(_offsetOf(tester, origin), _extent(2));
      for (var i = 0; i < 2; i++) {
        expect(
          _centerX(tester, 'T$i') - origin.dx,
          closeTo(inset + cell / 2 + i * (cell + gap), 1e-6),
          reason: 'T$i is outermost at the left edge in RTL',
        );
      }
    });

    testWidgets('the platter shows exactly what the row has uncovered', (
      tester,
    ) async {
      await _pump(tester, _row(leading: 1));
      final origin = _originOf(tester);

      // Pulled 50 px (the slop is forgiven): the trailing strip is the 50 px
      // at the right edge.
      final left = await _pull(tester, origin + const Offset(300, 36), -50);
      expect(_offsetOf(tester, origin), -50);
      var strip = tester.getRect(_stripOf('T0'));
      expect(strip.right, origin.dx + _kRowWidth);
      expect(strip.width, 50);
      await _lift(tester, left);
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), 0);

      // And the leading one at the left edge.
      final right = await _pull(tester, origin + const Offset(100, 36), 60);
      expect(_offsetOf(tester, origin), 60);
      strip = tester.getRect(_stripOf('L0'));
      expect(strip.left, origin.dx);
      expect(strip.width, 60);
      await _lift(tester, right);
      await tester.pumpAndSettle();
    });

    testWidgets('a side with actions is built and clipped to nothing while it '
        'is closed', (tester) async {
      await _pump(tester, _row(leading: 1));
      final origin = _originOf(tester);
      expect(find.byType(Button), findsNWidgets(3));
      expect(find.byType(PositionedDirectional), findsNWidgets(2));
      expect(_isClipped(tester, 'L0'), isTrue);
      expect(_isClipped(tester, 'T0'), isTrue);

      // Only the side the row has uncovered is drawn.
      await _openTrailing(tester, origin);
      expect(_stripWidth(tester, 'T0'), _extent(2));
      expect(_isClipped(tester, 'L0'), isTrue);

      await tester.tapAt(origin + const Offset(100, 36));
      await tester.pumpAndSettle();
      expect(_isClipped(tester, 'T0'), isTrue);
    });

    testWidgets('a side with no actions builds nothing', (tester) async {
      await _pump(tester, _row());
      expect(find.byType(PositionedDirectional), findsOneWidget);

      await _pump(tester, _row(trailing: 0));
      expect(find.byType(PositionedDirectional), findsNothing);
      expect(find.byType(Button), findsNothing);
    });

    testWidgets('a cell is a circular lg button with its label under it', (
      tester,
    ) async {
      await _pump(tester, _row(trailing: 1));
      final origin = _originOf(tester);
      await _openTrailing(tester, origin, count: 1);

      final button = tester.widget<Button>(_cellButton('T0'));
      expect(button.shape, CoreSwipeActionsContract.actionButtonShape);
      expect(button.size, CoreSwipeActionsContract.actionButtonSize);
      expect(button.variant, CoreButtonVariant.secondary);

      final buttonRect = tester.getRect(_cellButton('T0'));
      final labelRect = tester.getRect(find.text('T0'));
      expect(buttonRect.width, 48);
      expect(buttonRect.height, 48);
      // The label is under the button, centred on it, `labelGap` away.
      expect(labelRect.top, closeTo(buttonRect.bottom + 4, 1e-6));
      expect(labelRect.center.dx, closeTo(buttonRect.center.dx, 1e-6));
      // The button and its label are centred as one block in the row.
      expect(
        (buttonRect.top + labelRect.bottom) / 2,
        closeTo(origin.dy + _kRowHeight / 2, 1e-6),
      );

      final label = tester.widget<Text>(find.text('T0'));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
      expect(label.textAlign, TextAlign.center);
    });

    testWidgets('a long label is held to the cell, on one line', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: _kRowWidth,
          height: _kRowHeight,
          child: SwipeActions(
            trailingActions: [
              CoreSwipeAction<Widget>(
                label: 'Mark this conversation as unread',
                icon: const Icon(LucideIcons.x),
                onPressed: () {},
              ),
            ],
            child: _plainRow(),
          ),
        ),
      );
      final origin = _originOf(tester);
      await _openTrailing(tester, origin, count: 1);

      final label = tester.getRect(
        find.text('Mark this conversation as unread'),
      );
      expect(label.width, lessThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('showLabels: false draws the buttons alone', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row(showLabels: false));
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      expect(find.text('T0'), findsNothing);
      expect(find.byType(Button), findsNWidgets(2));
      // The label is still the button's name.
      expect(find.bySemanticsLabel('T0'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a platter fill paints, and none paints nothing', (
      tester,
    ) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);
      // The default platter is transparent: its strip is the clip around the
      // cells and nothing is painted behind them.
      expect(
        _stripChild(tester.widget<PositionedDirectional>(_stripOf('T0'))),
        isA<ClipRect>(),
      );

      const fill = CoreColor(0xFF336699);
      await _pump(
        tester,
        _row(style: const CoreSwipeActionsStyle(platterColor: fill)),
      );
      await _openTrailing(tester, _originOf(tester));

      final strip = _stripChild(
        tester.widget<PositionedDirectional>(_stripOf('T0')),
      );
      expect(strip, isA<ColoredBox>());
      expect((strip as ColoredBox).color, const Color(0xFF336699));
      // The fill is the strip the row uncovered: the platter's width.
      expect(
        tester.getSize(find.byWidget(strip)),
        Size(_extent(2), _kRowHeight),
      );
    });
  });

  group('SwipeActions actions', () {
    testWidgets('pressing an action runs it, then closes the row', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(tester, _row(log: log, trailing: 3));
      final origin = _originOf(tester);
      await _openTrailing(tester, origin, count: 3);
      expect(log, isEmpty);

      await tester.tap(_cellButton('T1'));
      await tester.pumpAndSettle();

      expect(log, ['T1']);
      expect(_offsetOf(tester, origin), 0);
    });

    testWidgets('a disabled action cannot be pressed, and is drawn as such', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(
        tester,
        _row(log: log, disabledTrailing: {1}),
      );
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      expect(tester.widget<Button>(_cellButton('T1')).enabled, isFalse);
      expect(tester.widget<Button>(_cellButton('T0')).enabled, isTrue);
      await tester.tap(_cellButton('T1'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(log, isEmpty);
      expect(_offsetOf(tester, origin), -_extent(2), reason: 'still open');
    });

    testWidgets('a destructive action is the destructive button', (
      tester,
    ) async {
      await _pump(tester, _row(destructiveTrailing: {0}));
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      expect(
        tester.widget<Button>(_cellButton('T0')).variant,
        CoreButtonVariant.destructive,
      );
      expect(
        tester.widget<Button>(_cellButton('T1')).variant,
        CoreButtonVariant.secondary,
      );
    });

    testWidgets('an action with no icon still draws its button', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: _kRowWidth,
          height: _kRowHeight,
          child: SwipeActions(
            trailingActions: [
              CoreSwipeAction<Widget>(label: 'Plain', onPressed: () {}),
            ],
            child: _plainRow(),
          ),
        ),
      );
      final origin = _originOf(tester);
      await _openTrailing(tester, origin, count: 1);

      expect(find.byType(Button), findsOneWidget);
      expect(find.text('Plain'), findsOneWidget);
    });
  });

  group('SwipeActions gestures', () {
    testWidgets('a full swipe runs only the first action, then closes', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(tester, _row(log: log, leading: 2, trailing: 3));
      final origin = _originOf(tester);

      // Pulled to the threshold (the slop is forgiven): 0.65 of the row.
      final stroke = await _pull(
        tester,
        origin + const Offset(380, 36),
        -(0.65 * _kRowWidth + 4),
      );
      await _lift(tester, stroke);
      await tester.pumpAndSettle();

      expect(log, ['T0'], reason: 'the first of three, and nothing else');
      expect(_offsetOf(tester, origin), 0);

      log.clear();
      final other = await _pull(
        tester,
        origin + const Offset(20, 36),
        0.65 * _kRowWidth + 4,
      );
      await _lift(tester, other);
      await tester.pumpAndSettle();

      expect(log, ['L0']);
      expect(_offsetOf(tester, origin), 0);
    });

    testWidgets('allowsFullSwipe: false resists past the platter and opens', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(
        tester,
        _row(log: log, allowsFullSwipe: false),
      );
      final origin = _originOf(tester);

      // 300 px of travel past the slop: 132 follows, the rest at a quarter.
      final stroke = await _pull(
        tester,
        origin + const Offset(380, 36),
        -300,
      );
      expect(
        _offsetOf(tester, origin),
        closeTo(
          -(_extent(2) +
              (300 - _extent(2)) * CoreSwipeActionsContract.defaultResistance),
          1e-6,
        ),
      );
      await _lift(tester, stroke);
      await tester.pumpAndSettle();

      expect(log, isEmpty);
      expect(_offsetOf(tester, origin), -_extent(2));
    });

    testWidgets('a disabled first action takes the full swipe away', (
      tester,
    ) async {
      final log = <String>[];
      await _pump(
        tester,
        _row(log: log, disabledTrailing: {0}),
      );
      final origin = _originOf(tester);

      final stroke = await _pull(
        tester,
        origin + const Offset(380, 36),
        -300,
      );
      await _lift(tester, stroke);
      await tester.pumpAndSettle();

      expect(log, isEmpty, reason: 'the first action cannot run');
      expect(_offsetOf(tester, origin), -_extent(2), reason: 'it opens');
    });

    // The first action of a side is what a full swipe runs; with nothing to
    // run there is no full swipe, on the leading side as on the trailing one
    // and whichever way the text reads. The pull resists past the platter and
    // the row opens — it does not close as a row that ran an action would.
    for (final rtl in [false, true]) {
      testWidgets(
        'a disabled first leading action takes the full swipe away '
        '(${rtl ? 'right-to-left' : 'left-to-right'})',
        (tester) async {
          final log = <String>[];
          await _pump(
            tester,
            _row(log: log, leading: 2, trailing: 0, disabledLeading: {0}),
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          );
          final origin = _originOf(tester);

          // The leading platter is at the start edge: it opens by pulling
          // right, or left when the text reads right to left.
          final sign = rtl ? -1.0 : 1.0;
          final stroke = await _pull(
            tester,
            origin + Offset(rtl ? 380 : 20, 36),
            sign * 300,
          );
          expect(
            _offsetOf(tester, origin),
            closeTo(
              sign *
                  (_extent(2) +
                      (300 - _extent(2)) *
                          CoreSwipeActionsContract.defaultResistance),
              1e-6,
            ),
            reason: 'past the platter it resists',
          );
          await _lift(tester, stroke);
          await tester.pumpAndSettle();

          expect(log, isEmpty, reason: 'the first action cannot run');
          expect(
            _offsetOf(tester, origin),
            sign * _extent(2),
            reason: 'it opens',
          );
        },
      );
    }

    group('when the actions change under the finger', () {
      // The release is decided by the pull the row was given; what it runs is
      // the first action of the side as it is at the lift.
      Future<
        ({
          ValueNotifier<Widget> content,
          ({TestGesture gesture, Duration clock}) stroke,
        })
      >
      pullThroughTheThreshold(WidgetTester tester, List<String> log) async {
        final content = await _pumpLive(tester, _row(log: log));
        final origin = _originOf(tester);
        final stroke = await _pull(
          tester,
          origin + const Offset(380, 36),
          -(0.65 * _kRowWidth + 4),
        );

        return (content: content, stroke: stroke);
      }

      testWidgets('a first action disabled meanwhile is not run by the lift', (
        tester,
      ) async {
        final log = <String>[];
        final held = await pullThroughTheThreshold(tester, log);

        held.content.value = _row(log: log, disabledTrailing: {0});
        await tester.pump();
        await _lift(tester, held.stroke);
        await tester.pumpAndSettle();

        expect(log, isEmpty, reason: 'it can no longer be run');
      });

      testWidgets('a first action replaced meanwhile: the new one runs, once', (
        tester,
      ) async {
        final log = <String>[];
        final held = await pullThroughTheThreshold(tester, log);

        held.content.value = _scroller(
          SizedBox(
            width: _kRowWidth,
            height: _kRowHeight,
            child: SwipeActions(
              trailingActions: _actions('N', 2, log: log),
              child: _plainRow(),
            ),
          ),
        );
        await tester.pump();
        await _lift(tester, held.stroke);
        await tester.pumpAndSettle();

        expect(log, ['N0'], reason: 'the first action as it is at the lift');
      });

      testWidgets('a first action still there and enabled runs as before', (
        tester,
      ) async {
        final log = <String>[];
        final held = await pullThroughTheThreshold(tester, log);

        held.content.value = _row(log: log, destructiveTrailing: {0});
        await tester.pump();
        await _lift(tester, held.stroke);
        await tester.pumpAndSettle();

        expect(log, ['T0']);
      });
    });

    testWidgets('the full-swipe threshold is the one the widget was given', (
      tester,
    ) async {
      final log = <String>[];
      // 0.4 of a 400 px row: 160 px runs it.
      await _pump(
        tester,
        _row(log: log, fullSwipeThreshold: 0.4),
      );
      final origin = _originOf(tester);
      var stroke = await _pull(
        tester,
        origin + const Offset(380, 36),
        -162,
      );
      await _lift(tester, stroke);
      await tester.pumpAndSettle();
      expect(log, ['T0']);

      log.clear();
      // 0.9: 360 px; 300 px only opens.
      await _pump(
        tester,
        _row(log: log, fullSwipeThreshold: 0.9),
      );
      stroke = await _pull(tester, origin + const Offset(380, 36), -300);
      await _lift(tester, stroke);
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(_offsetOf(tester, origin), -_extent(2));
    });

    testWidgets('a drag that starts on an open row stays on its side', (
      tester,
    ) async {
      await _pump(tester, _row(leading: 1));
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      // Pulled right, across closed and toward the leading platter: the row
      // closes and stops there.
      final stroke = await _slowPull(
        tester,
        origin + const Offset(100, 36),
        260,
      );
      expect(_offsetOf(tester, origin), 0);
      await _lift(tester, stroke);
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), 0);
      expect(_isClipped(tester, 'L0'), isTrue);
      expect(_isClipped(tester, 'T0'), isTrue);
    });

    testWidgets('a vertical stroke belongs to the list, not the row', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        SizedBox(
          width: _kRowWidth,
          height: 300,
          child: ListView(
            controller: controller,
            children: [
              SizedBox(
                height: _kRowHeight,
                child: SwipeActions(
                  trailingActions: _actions('T', 2),
                  child: _plainRow(),
                ),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      );
      final origin = _originOf(tester);

      final stroke = await _pressAndStroke(
        tester,
        origin + const Offset(300, 36),
        const Offset(-6, -50),
        const Duration(milliseconds: 600),
      );

      // The list took the stroke: it scrolled, and the row did not move
      // sideways with the few pixels of drift.
      expect(controller.offset, greaterThan(20));
      expect(_offsetOf(tester, origin), 0);
      await _lift(tester, stroke);
      await tester.pumpAndSettle();
      expect(_isClipped(tester, 'T0'), isTrue);
    });

    testWidgets('a horizontal drag in a list does not scroll it', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        SizedBox(
          width: _kRowWidth,
          height: 300,
          child: ListView(
            controller: controller,
            children: [
              SizedBox(
                height: _kRowHeight,
                child: SwipeActions(
                  trailingActions: _actions('T', 2),
                  child: _plainRow(),
                ),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      );
      final origin = _originOf(tester);

      final stroke = await _pressAndStroke(
        tester,
        origin + const Offset(300, 36),
        const Offset(-100, 6),
        const Duration(milliseconds: 600),
      );
      await _lift(tester, stroke);
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
      expect(_offsetOf(tester, origin), -_extent(2));
    });

    testWidgets('a disabled row cannot be swiped', (tester) async {
      await _pump(tester, _row(enabled: false));
      final origin = _originOf(tester);

      final stroke = await _slowPull(
        tester,
        origin + const Offset(300, 36),
        -150,
      );
      expect(_offsetOf(tester, origin), 0);
      await _lift(tester, stroke);
      await tester.pumpAndSettle();

      expect(_offsetOf(tester, origin), 0);
      expect(find.byType(Button), findsNothing);
    });

    testWidgets('a row disabled while open goes closed', (tester) async {
      final content = await _pumpLive(tester, _row());
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);
      expect(_offsetOf(tester, origin), -_extent(2));

      content.value = _row(enabled: false);
      await tester.pumpAndSettle();

      expect(_offsetOf(tester, origin), 0);
      expect(find.byType(Button), findsNothing);
    });

    testWidgets('actions that change but not in number leave an open row '
        'open', (tester) async {
      final content = await _pumpLive(tester, _row());
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);
      expect(_offsetOf(tester, origin), -_extent(2));

      content.value = _row(destructiveTrailing: {0});
      await tester.pumpAndSettle();

      expect(_offsetOf(tester, origin), -_extent(2));
      expect(find.byType(Button), findsNWidgets(2));
    });

    group('when the actions change in number', () {
      // The open travel is the width of the platter the row uncovers, a
      // function of how many actions there are: an open row would rest at the
      // old width, covering the new cells or leaving dead space.
      late CoreSwipeExclusivity exclusivity;

      Widget tree({
        required int trailing,
        int leading = 0,
        CoreSwipeActionsStyle? style,
      }) => SwipeActionScope(
        child: Builder(
          builder: (context) {
            exclusivity = SwipeActionScope.maybeOf(context)!;

            return _row(leading: leading, trailing: trailing, style: style);
          },
        ),
      );

      testWidgets('an open row closes, and lets go of its scope', (
        tester,
      ) async {
        final content = await _pumpLive(tester, tree(trailing: 2));
        final origin = _originOf(tester);
        await _openTrailing(tester, origin);
        expect(_offsetOf(tester, origin), -_extent(2));
        expect(exclusivity.holder, isNotNull);

        content.value = tree(trailing: 3);
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), 0);
        expect(_isClipped(tester, 'T0'), isTrue);
        expect(
          exclusivity.holder,
          isNull,
          reason: 'it is closed again, so the claim is released',
        );
      });

      testWidgets('either side counts', (tester) async {
        final content = await _pumpLive(tester, tree(trailing: 2));
        final origin = _originOf(tester);
        await _openTrailing(tester, origin);
        expect(_offsetOf(tester, origin), -_extent(2));

        // An action appears on the other side: the open side's travel is
        // unchanged, but the row is no longer what the finger opened.
        content.value = tree(trailing: 2, leading: 1);
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), 0);
        expect(exclusivity.holder, isNull);
      });

      testWidgets('fewer actions close it too', (tester) async {
        final content = await _pumpLive(tester, tree(trailing: 3));
        final origin = _originOf(tester);
        await _openTrailing(tester, origin, count: 3);
        expect(_offsetOf(tester, origin), -_extent(3));

        content.value = tree(trailing: 1);
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), 0);
      });

      testWidgets('the same number of actions leaves the row open', (
        tester,
      ) async {
        final content = await _pumpLive(tester, tree(trailing: 2));
        final origin = _originOf(tester);
        await _openTrailing(tester, origin);

        // Another style, same count: the row has nowhere else to be.
        content.value = tree(
          trailing: 2,
          style: const CoreSwipeActionsStyle(
            labelGapStyle: CoreGapStyle(size: 8),
          ),
        );
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), -_extent(2));
        expect(exclusivity.holder, isNotNull);
      });

      testWidgets('a closed row stays closed and quiet', (tester) async {
        final content = await _pumpLive(tester, tree(trailing: 2));
        final origin = _originOf(tester);

        content.value = tree(trailing: 3);
        await tester.pump();

        expect(_offsetOf(tester, origin), 0);
        expect(tester.hasRunningAnimations, isFalse);
        expect(exclusivity.holder, isNull);
      });
    });

    testWidgets('a row with no actions does not move', (tester) async {
      await _pump(tester, _row(trailing: 0));
      final origin = _originOf(tester);

      final stroke = await _slowPull(
        tester,
        origin + const Offset(300, 36),
        -150,
      );
      await _lift(tester, stroke);
      await tester.pumpAndSettle();

      expect(_offsetOf(tester, origin), 0);
    });

    testWidgets('tapping the open row closes it and does not reach the child', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, _row(child: _plainRow(onTap: () => taps++)));
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);
      expect(_offsetOf(tester, origin), -_extent(2));

      await tester.tapAt(origin + const Offset(100, 36));
      await tester.pumpAndSettle();

      expect(taps, 0);
      expect(_offsetOf(tester, origin), 0);

      // Closed again, the child is reachable.
      await tester.tapAt(origin + const Offset(100, 36));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a drag can pick the row up while it is still settling', (
      tester,
    ) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);

      final stroke = await _slowPull(
        tester,
        origin + const Offset(300, 36),
        -118,
      );
      await _lift(tester, stroke);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final midway = _offsetOf(tester, origin);
      expect(midway, lessThan(-100));
      expect(midway, greaterThan(-_extent(2)));

      // Grab it where it is: arming the drag does not move it.
      final grab = await tester.startGesture(origin + const Offset(200, 36));
      await grab.moveTo(origin + const Offset(230, 36), timeStamp: _kFrame);
      await tester.pump();
      expect(_offsetOf(tester, origin), closeTo(midway, 1e-6));

      // And it then follows the pointer from there.
      await grab.moveTo(origin + const Offset(250, 36), timeStamp: _kFrame * 2);
      await tester.pump();
      expect(_offsetOf(tester, origin), closeTo(midway + 20, 1e-6));
      await grab.up(timeStamp: _kFrame * 3);
      await tester.pumpAndSettle();
    });

    testWidgets('moving the widget under the other direction closes the row', (
      tester,
    ) async {
      await pumpTestApp(tester, _row());
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);
      expect(_offsetOf(tester, origin), -_extent(2));

      await pumpTestApp(tester, _row(), textDirection: TextDirection.rtl);
      await tester.pumpAndSettle();

      expect(_offsetOf(tester, origin), 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('SwipeActions motion', () {
    testWidgets('a released row settles on a spring that is at rest by its '
        'duration', (tester) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);

      final stroke = await _pull(
        tester,
        origin + const Offset(300, 36),
        -100,
      );
      expect(_offsetOf(tester, origin), -100);
      await _lift(tester, stroke);
      await tester.pump();

      // Half the duration in: on its way, not there.
      await tester.pump(CoreSwipeActionsContract.defaultSettleDuration ~/ 2);
      final half = _offsetOf(tester, origin);
      expect(half, lessThan(-100));
      expect(half, greaterThan(-132));

      // At its duration: within 2% of the way it had to travel.
      await tester.pump(CoreSwipeActionsContract.defaultSettleDuration ~/ 2);
      expect(
        (_offsetOf(tester, origin) - -132).abs(),
        lessThan(0.02 * (132 - 100)),
      );

      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), -132);
    });

    testWidgets('the settle never crosses its target, however hard the flick', (
      tester,
    ) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);

      // 60 px in 12 ms: 5000 px/s, past what the spring can use without
      // overshooting the open position 52 px away.
      final stroke = await _pressAndStroke(
        tester,
        origin + const Offset(300, 36),
        const Offset(-100, 0),
        const Duration(milliseconds: 12),
        frame: const Duration(milliseconds: 4),
      );
      await _lift(tester, stroke);

      var furthest = _offsetOf(tester, origin);
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        final now = _offsetOf(tester, origin);
        if (now < furthest) furthest = now;
      }

      expect(furthest, greaterThanOrEqualTo(-_extent(2) - 0.5));
      expect(_offsetOf(tester, origin), -_extent(2));
    });

    testWidgets('the speed of the lift starts the spring moving', (
      tester,
    ) async {
      // The same pull — the row 100 px open at the lift — released twice:
      // while the finger is still going, and after it stopped. Both settle on
      // the open position. The flick is well along after a frame or two
      // because the spring starts at the speed of the finger rather than at
      // rest, which is the difference between a row that is thrown open and
      // one that is only let go.
      Future<({double lifted, List<double> moved, double rest})> release({
        required bool flick,
      }) async {
        await _pump(tester, _row());
        final origin = _originOf(tester);
        final start = origin + const Offset(300, 36);
        final stroke = flick
            ? await _pull(
                tester,
                start,
                -100,
                over: const Duration(milliseconds: 80),
              )
            : await _pull(tester, start, -100);
        final lifted = _offsetOf(tester, origin);
        await _lift(
          tester,
          stroke,
          hold: flick ? Duration.zero : const Duration(milliseconds: 300),
        );
        await tester.pump();

        // How far each of the first frames took the row from where it was
        // lifted.
        final moved = <double>[];
        for (var i = 0; i < 2; i++) {
          await tester.pump(_kFrame);
          moved.add((_offsetOf(tester, origin) - lifted).abs());
        }
        await tester.pumpAndSettle();

        return (
          lifted: lifted,
          moved: moved,
          rest: _offsetOf(tester, origin),
        );
      }

      final flick = await release(flick: true);
      final pause = await release(flick: false);

      expect(flick.lifted, -100);
      expect(pause.lifted, -100, reason: 'the same place at the lift');
      for (var frame = 0; frame < 2; frame++) {
        expect(
          flick.moved[frame],
          greaterThan(pause.moved[frame] + 4),
          reason:
              'frame ${frame + 1}: the flick moved ${flick.moved[frame]} px, '
              'the pause ${pause.moved[frame]} px',
        );
      }
      expect(flick.rest, -_extent(2));
      expect(pause.rest, -_extent(2), reason: 'both settle on the same place');
    });

    testWidgets('a flick toward a side with no actions does not move the row', (
      tester,
    ) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);

      // Trailing actions only; the flick goes right, toward nothing. The row
      // never leaves rest — and the speed of the flick is not carried into
      // its settle.
      final stroke = await _pressAndStroke(
        tester,
        origin + const Offset(100, 36),
        const Offset(80, 0),
        const Duration(milliseconds: 48),
        frame: const Duration(milliseconds: 8),
      );
      expect(_offsetOf(tester, origin), 0);
      await _lift(tester, stroke);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        expect(_offsetOf(tester, origin), 0, reason: 'frame $i');
      }
    });

    testWidgets(
      'with reduced motion the row jumps, with no frames in between',
      (
        tester,
      ) async {
        await _pump(tester, _row(), disableAnimations: true);
        final origin = _originOf(tester);

        final stroke = await _slowPull(
          tester,
          origin + const Offset(300, 36),
          -118,
        );
        await _lift(tester, stroke);
        await tester.pump();

        expect(_offsetOf(tester, origin), -_extent(2));
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('without it the same release is still on its way', (
      tester,
    ) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);

      final stroke = await _slowPull(
        tester,
        origin + const Offset(300, 36),
        -118,
      );
      await _lift(tester, stroke);
      await tester.pump();

      expect(_offsetOf(tester, origin), isNot(-_extent(2)));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), -_extent(2));
    });

    testWidgets('the full-swipe cue grows the first cell, and only in the '
        'zone', (tester) async {
      await _pump(
        tester,
        _row(
          trailing: 3,
          style: const CoreSwipeActionsStyle(fullSwipeScale: 1.25),
        ),
      );
      final origin = _originOf(tester);
      double glyph(String tag) =>
          tester.getRect(find.byKey(ValueKey(tag))).width;

      // Out in the open but short of the threshold: nothing grows.
      final start = origin + const Offset(380, 36);
      final stroke = await _pull(tester, start, -200);
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), -200);
      expect(glyph('T0'), glyph('T1'));
      expect(glyph('T1'), glyph('T2'));
      final unit = glyph('T1');

      // Into the zone (0.65 of the row, 260): the first cell grows.
      await stroke.gesture.moveTo(
        start + const Offset(-20 - 280, 0),
        timeStamp: stroke.clock + _kFrame,
      );
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, origin), -280);
      expect(glyph('T0'), closeTo(unit * 1.25, 1e-6));
      expect(glyph('T1'), unit);
      expect(glyph('T2'), unit);

      // And back out: it goes back.
      await stroke.gesture.moveTo(
        start + const Offset(-20 - 200, 0),
        timeStamp: stroke.clock + _kFrame * 2,
      );
      await tester.pumpAndSettle();
      expect(glyph('T0'), unit);
      await stroke.gesture.up(timeStamp: stroke.clock + _kFrame * 3);
      await tester.pumpAndSettle();
    });

    testWidgets('no cue is drawn by default', (tester) async {
      await _pump(tester, _row(trailing: 3));
      final origin = _originOf(tester);
      final stroke = await _slowPull(
        tester,
        origin + const Offset(380, 36),
        -300,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedScale), findsNothing);
      await _lift(tester, stroke);
      await tester.pumpAndSettle();
    });
  });

  group('SwipeActions semantics', () {
    testWidgets('every enabled action is a custom action of the row', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _row(leading: 1, trailing: 3, disabledTrailing: {1}),
      );

      final node = tester.getSemantics(find.byKey(_kRowKey));
      expect(_customLabels(node), {'L0', 'T0', 'T2'});
      handle.dispose();
    });

    // A screen reader's action menu is a list: the leading actions outermost
    // first, then the trailing ones outermost last — the order they sit in
    // from the start edge of the row to its end edge, which is the same list
    // whichever way the text reads.
    for (final rtl in [false, true]) {
      final direction = rtl ? 'right-to-left' : 'left-to-right';
      testWidgets('the custom actions are listed leading first, outermost '
          'first, then trailing, outermost last ($direction)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        // Labels no other test uses, so that the ids a node reports for them
        // are handed out here, in the order the row declares them.
        final tag = rtl ? 'rtl' : 'ltr';
        await _pump(
          tester,
          SizedBox(
            width: _kRowWidth,
            height: _kRowHeight,
            child: SwipeActions(
              leadingActions: _actions('${tag}L', 2),
              trailingActions: _actions('${tag}T', 3),
              child: _plainRow(),
            ),
          ),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        );

        final expected = [
          '${tag}L0',
          '${tag}L1',
          '${tag}T2',
          '${tag}T1',
          '${tag}T0',
        ];
        expect(_declaredActionOrder(tester), expected);
        final node = tester.getSemantics(find.byKey(_kRowKey));
        expect(
          [
            for (final id
                in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
              CustomSemanticsAction.getAction(id)!.label!,
          ],
          expected,
          reason: 'what the node reports is what the row declared',
        );
        handle.dispose();
      });
    }

    testWidgets('running one runs the action and closes the row', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      await _pump(tester, _row(log: log));
      final origin = _originOf(tester);

      // Closed: reachable all the same.
      _runCustomAction(tester.getSemantics(find.byKey(_kRowKey)), 'T1');
      await tester.pumpAndSettle();
      expect(log, ['T1']);
      expect(_offsetOf(tester, origin), 0);

      // Open: it runs, and the row closes.
      await _openTrailing(tester, origin);
      log.clear();
      _runCustomAction(tester.getSemantics(find.byKey(_kRowKey)), 'T0');
      await tester.pumpAndSettle();
      expect(log, ['T0']);
      expect(_offsetOf(tester, origin), 0);
      handle.dispose();
    });

    testWidgets('the platters are not in semantics while the row is closed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row());
      final origin = _originOf(tester);

      expect(find.bySemanticsLabel('T0'), findsNothing);
      expect(find.bySemanticsLabel('T1'), findsNothing);

      // Opened: each action is a button named by its label — once, not
      // again for the label drawn under it. The match is on the word, not the
      // whole name, so a label that merged into a neighbouring node is seen
      // too.
      await _openTrailing(tester, origin);
      expect(find.bySemanticsLabel(RegExp(r'\bT0\b')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'\bT1\b')), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('T0'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.getSemanticsData().label, 'T0');

      // And pressing it through semantics is pressing it.
      final log = <String>[];
      await _pump(tester, _row(log: log));
      await _openTrailing(tester, origin);
      final press = tester.getSemantics(find.bySemanticsLabel('T0'));
      press.owner!.performAction(press.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(log, ['T0']);
      expect(_offsetOf(tester, origin), 0);
      handle.dispose();
    });

    testWidgets('a closed row exposes its actions only as custom actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row(leading: 1));

      // Laid out for a keyboard, clipped to nothing on screen: a screen reader
      // is shown no button it could not see.
      expect(find.byType(Button), findsNWidgets(3));
      expect(_buttonNodes(tester), isEmpty);
      expect(
        _customLabels(tester.getSemantics(find.byKey(_kRowKey))),
        {'L0', 'T0', 'T1'},
      );
      handle.dispose();
    });

    testWidgets('an open side puts its buttons into the tree, once each, and '
        'the closed side stays out', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row(leading: 1));
      final origin = _originOf(tester);

      await _openTrailing(tester, origin);
      expect(_buttonLabels(tester), {'T0', 'T1'});
      expect(_buttonNodes(tester), hasLength(2));
      expect(find.bySemanticsLabel(RegExp(r'\bL0\b')), findsNothing);
      // The custom actions are still all of them, the open side included.
      expect(
        _customLabels(tester.getSemantics(find.byKey(_kRowKey))),
        {'L0', 'T0', 'T1'},
      );

      await tester.tapAt(origin + const Offset(100, 36));
      await tester.pumpAndSettle();
      expect(_buttonNodes(tester), isEmpty);

      await _openLeading(tester, origin);
      expect(_buttonLabels(tester), {'L0'});
      handle.dispose();
    });

    testWidgets('focus brings the focused side into the tree, and the node '
        'of the focused action carries the focus', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _walk(_row(leading: 1)));
      await tester.pump();
      expect(_buttonNodes(tester), isEmpty);

      // The stops are L0, T1, T0.
      await _tabs(tester, 2);
      await tester.pumpAndSettle();
      expect(_focused(tester), 'T1');
      expect(_buttonLabels(tester), {'T0', 'T1'});

      Tristate focus(String label) => tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData()
          .flagsCollection
          .isFocused;
      expect(focus('T1'), Tristate.isTrue);
      // The other action can take focus too; it just does not have it.
      expect(focus('T0'), Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('a disabled action is not a focus target in the tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row(disabledTrailing: {0}));
      final origin = _originOf(tester);

      await _openTrailing(tester, origin);
      final data = tester
          .getSemantics(find.bySemanticsLabel('T0'))
          .getSemanticsData();
      expect(data.flagsCollection.isFocused, Tristate.none);
      handle.dispose();
    });

    testWidgets("the keyboard plumbing adds nothing to the row's own node", (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row());

      final data = tester.getSemantics(find.byKey(_kRowKey)).getSemanticsData();
      expect(data.flagsCollection.isFocused, Tristate.none);
      expect(data.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a disabled action is not offered, and is not enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row(disabledTrailing: {0}));
      final origin = _originOf(tester);

      expect(
        _customLabels(tester.getSemantics(find.byKey(_kRowKey))),
        {'T1'},
      );
      await _openTrailing(tester, origin);
      final node = tester.getSemantics(find.bySemanticsLabel('T0'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('a disabled row offers no actions', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row(enabled: false));

      expect(
        _customLabels(tester.getSemantics(find.byKey(_kRowKey))),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('swiping adds no scroll actions to the row', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _row());

      final data = tester.getSemantics(find.byKey(_kRowKey)).getSemanticsData();
      expect(data.hasAction(SemanticsAction.scrollLeft), isFalse);
      expect(data.hasAction(SemanticsAction.scrollRight), isFalse);
      handle.dispose();
    });
  });

  group('SwipeActions keyboard', () {
    // The order the Web seat's DOM has: the leading actions as declared, the
    // row's own content, the trailing actions backwards — each platter reads
    // from its start edge to its end edge, and the outermost action is at the
    // outer edge.
    const dom = ['L0', 'L1', 'content', 'T1', 'T0'];

    Future<void> mount(
      WidgetTester tester,
      Widget row, {
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      await _pump(tester, _walk(row), textDirection: textDirection);
      await tester.pump();
      expect(_focused(tester), 'start');
    }

    Widget fullRow({
      int leading = 2,
      int trailing = 2,
      Set<int> disabledTrailing = const {},
      bool enabled = true,
      List<String>? log,
    }) => _row(
      leading: leading,
      trailing: trailing,
      disabledTrailing: disabledTrailing,
      enabled: enabled,
      log: log,
      child: _focusableRow(),
    );

    group('Tab', () {
      testWidgets('reaches every action of a closed row, in the DOM order', (
        tester,
      ) async {
        await mount(tester, fullRow());

        expect(await _tabs(tester, 6), [...dom, 'end']);
        // And back the way it came.
        expect(await _tabs(tester, 5, shift: true), [
          'T0',
          'T1',
          'content',
          'L1',
          'L0',
        ]);
        expect(await _tabs(tester, 1, shift: true), ['start']);
      });

      testWidgets('walks the same order under right-to-left', (tester) async {
        await mount(tester, fullRow(), textDirection: TextDirection.rtl);

        // The leading actions are at the right edge now; the order is the
        // DOM's, not the screen's left to right.
        expect(await _tabs(tester, 6), [...dom, 'end']);
        expect(await _tabs(tester, 5, shift: true), [
          'T0',
          'T1',
          'content',
          'L1',
          'L0',
        ]);
      });

      testWidgets('does not take the order from where the cells are laid out', (
        tester,
      ) async {
        // A row narrower than its actions lays the two platters over one
        // another, so positions say nothing about the order.
        await mount(
          tester,
          _scroller(
            SizedBox(
              width: 150,
              height: _kRowHeight,
              child: SwipeActions(
                leadingActions: _actions('L', 3),
                trailingActions: _actions('T', 3),
                child: _focusableRow(),
              ),
            ),
          ),
        );

        expect(await _tabs(tester, 8), [
          'L0',
          'L1',
          'L2',
          'content',
          'T2',
          'T1',
          'T0',
          'end',
        ]);
      });

      testWidgets('skips a disabled action', (tester) async {
        await mount(tester, fullRow(disabledTrailing: {0}));

        expect(await _tabs(tester, 5), ['L0', 'L1', 'content', 'T1', 'end']);
      });

      testWidgets('finds nothing in a disabled row, or one with no actions', (
        tester,
      ) async {
        await mount(tester, fullRow(enabled: false));
        expect(find.byType(Button), findsNothing);
        expect(await _tabs(tester, 2), ['content', 'end']);

        await mount(tester, fullRow(leading: 0, trailing: 0));
        expect(await _tabs(tester, 2), ['content', 'end']);
      });
    });

    group('focus on an action', () {
      testWidgets('opens its side, wherever the side is on screen', (
        tester,
      ) async {
        await mount(tester, fullRow());
        final origin = _originOf(tester);

        await _tabs(tester, 1);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'L0');
        expect(_offsetOf(tester, origin), _extent(2));
        expect(_stripWidth(tester, 'L0'), _extent(2));
        expect(_isClipped(tester, 'T0'), isTrue);

        // Another action of the open side leaves it as it is.
        await _tabs(tester, 1);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'L1');
        expect(_offsetOf(tester, origin), _extent(2));

        // The other side's: the row crosses closed and opens there.
        await _tabs(tester, 2);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'T1');
        expect(_offsetOf(tester, origin), -_extent(2));
        expect(_stripWidth(tester, 'T1'), _extent(2));
        expect(_isClipped(tester, 'L0'), isTrue);
      });

      testWidgets('opens the side the reading direction puts it on', (
        tester,
      ) async {
        await mount(tester, fullRow(), textDirection: TextDirection.rtl);
        final origin = _originOf(tester);

        await _tabs(tester, 1);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'L0');
        // The leading side is on the right in RTL: the row moves left.
        expect(_offsetOf(tester, origin), -_extent(2));
        expect(
          _centerX(tester, 'L0') - origin.dx,
          closeTo(_kRowWidth - 12 - 24, 1e-6),
          reason: 'L0 is the outermost action, at the right edge',
        );

        await _tabs(tester, 3);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'T1');
        expect(_offsetOf(tester, origin), _extent(2));
      });

      testWidgets('moving focus on does not close the row', (tester) async {
        await mount(tester, _row());
        final origin = _originOf(tester);

        expect(await _tabs(tester, 3), ['T1', 'T0', 'end']);
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), -_extent(2));
      });

      testWidgets('takes the scope, and closes the row that held it', (
        tester,
      ) async {
        final rowA = _scroller(
          SizedBox(
            width: _kRowWidth,
            height: _kRowHeight,
            child: SwipeActions(
              leadingActions: _actions('L', 2),
              child: _plainRow(key: const Key('a')),
            ),
          ),
        );
        final rowB = _scroller(
          SizedBox(
            width: _kRowWidth,
            height: _kRowHeight,
            child: SwipeActions(
              trailingActions: _actions('T', 2),
              child: _plainRow(key: const Key('b')),
            ),
          ),
        );
        late CoreSwipeExclusivity scope;
        await mount(
          tester,
          SwipeActionScope(
            child: Builder(
              builder: (context) {
                scope = SwipeActionScope.maybeOf(context)!;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    rowA,
                    rowB,
                  ],
                );
              },
            ),
          ),
        );
        final a = tester.getTopLeft(find.byKey(const Key('a')));
        final b = tester.getTopLeft(find.byKey(const Key('b')));
        double offsetOf(Key key, Offset origin) =>
            tester.getTopLeft(find.byKey(key)).dx - origin.dx;

        await _tabs(tester, 1);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'L0');
        expect(offsetOf(const Key('a'), a), _extent(2));
        expect(offsetOf(const Key('b'), b), 0);
        final holder = scope.holder;
        expect(holder, isNotNull);

        // Focus reaches the other row: it opens, and the first one closes.
        await _tabs(tester, 2);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'T1');
        expect(offsetOf(const Key('a'), a), 0);
        expect(offsetOf(const Key('b'), b), -_extent(2));
        expect(scope.holder, isNot(same(holder)));
        expect(scope.holder, isNotNull);
      });
    });

    group('Enter and Space', () {
      for (final (name, key) in [
        ('Enter', LogicalKeyboardKey.enter),
        ('Space', LogicalKeyboardKey.space),
      ]) {
        testWidgets('$name runs the focused action, closes the row and keeps '
            'focus on the row', (
          tester,
        ) async {
          final log = <String>[];
          await mount(tester, _row(log: log, trailing: 3));
          final origin = _originOf(tester);

          // Tab order is T2, T1, T0: the second stop.
          expect(await _tabs(tester, 2), ['T2', 'T1']);
          await tester.pumpAndSettle();
          expect(_offsetOf(tester, origin), -_extent(3));
          expect(log, isEmpty);

          await _key(tester, key);
          // At once, not when the row has come to rest: the action that had
          // focus is about to be clipped away.
          expect(_focused(tester), 'SwipeActions');
          await tester.pumpAndSettle();

          expect(log, ['T1']);
          expect(_offsetOf(tester, origin), 0);
          expect(_isClipped(tester, 'T1'), isTrue);
          expect(_focused(tester), 'SwipeActions');
        });
      }

      testWidgets('an action that sends focus elsewhere has moved it: closing '
          'the row takes none', (tester) async {
        final field = FocusNode(debugLabel: 'field');
        addTearDown(field.dispose);
        await mount(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scroller(
                SizedBox(
                  width: _kRowWidth,
                  height: _kRowHeight,
                  child: SwipeActions(
                    trailingActions: [
                      CoreSwipeAction<Widget>(
                        label: 'T0',
                        icon: const Icon(LucideIcons.x, key: ValueKey('T0')),
                        onPressed: field.requestFocus,
                      ),
                    ],
                    child: _plainRow(),
                  ),
                ),
              ),
              Focus(
                focusNode: field,
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
        );
        final origin = _originOf(tester);

        expect(await _tabs(tester, 1), ['T0']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(1));

        // The handler asks for focus; the framework applies the request a
        // moment later, after the row has asked for it too.
        await _key(tester, LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'field');
      });
    });

    group('Escape', () {
      testWidgets('closes an open row and gives focus back to the row', (
        tester,
      ) async {
        await mount(tester, _row());
        final origin = _originOf(tester);

        await _tabs(tester, 1);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'T1');
        expect(_offsetOf(tester, origin), -_extent(2));

        await _key(tester, LogicalKeyboardKey.escape);
        // At once, not when the row has come to rest.
        expect(_focused(tester), 'SwipeActions');
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('is stopped by the row only when it closed something', (
        tester,
      ) async {
        final heard = <LogicalKeyboardKey>[];
        await _pump(
          tester,
          Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) heard.add(event.logicalKey);

              return KeyEventResult.ignored;
            },
            child: _walk(_row(child: _focusableRow())),
          ),
        );
        await tester.pump();
        final origin = _originOf(tester);

        // A closed row has nothing to close: the key goes on, to whatever is
        // around it — a dialog that Escape closes.
        expect(await _tabs(tester, 1), ['content']);
        await _key(tester, LogicalKeyboardKey.escape);
        expect(heard, [LogicalKeyboardKey.escape]);

        // Another key goes on whether the row is open or not.
        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(2));
        heard.clear();
        await _key(tester, LogicalKeyboardKey.keyA);
        expect(heard, [LogicalKeyboardKey.keyA]);

        // The open row takes the key that closed it.
        await _key(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(heard, [LogicalKeyboardKey.keyA]);
        expect(_offsetOf(tester, origin), 0);

        // With the row closed again, the next one goes on.
        await _key(tester, LogicalKeyboardKey.escape);
        expect(heard, [LogicalKeyboardKey.keyA, LogicalKeyboardKey.escape]);
      });

      testWidgets('closes a row that is on its way open', (tester) async {
        await mount(tester, _row());
        final origin = _originOf(tester);

        // The row has been told to open and has not yet moved: it is open as
        // far as Escape is concerned.
        await _tabs(tester, 1);
        expect(_offsetOf(tester, origin), 0);
        expect(tester.hasRunningAnimations, isTrue);

        await _key(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });
    });

    group('when the row changes under a focused action', () {
      Future<ValueNotifier<Widget>> mountLive(
        WidgetTester tester,
        Widget row,
      ) async {
        final content = await _pumpLive(tester, _walk(row));
        await tester.pump();
        expect(_focused(tester), 'start');

        return content;
      }

      testWidgets('actions that change in number close it, focus on the row', (
        tester,
      ) async {
        final content = await mountLive(tester, _row(trailing: 3));
        final origin = _originOf(tester);

        // The third stop is T0: the cell the shorter row will not have.
        expect(await _tabs(tester, 3), ['T2', 'T1', 'T0']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(3));

        content.value = _walk(_row());
        // The cell that had focus is gone with this build: focus is already
        // on the row, not left to the framework to find a place for.
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_focused(tester), 'SwipeActions');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('actions that change in number while it is only starting to '
          'open close it too', (tester) async {
        final content = await mountLive(tester, _row());
        final origin = _originOf(tester);

        // Told to open, not yet moved: its travel is still the old width.
        expect(await _tabs(tester, 1), ['T1']);
        expect(_offsetOf(tester, origin), 0);

        // The rebuild comes in a frame that moves the clock by nothing, so
        // the row is still where it was when it was told to open.
        content.value = _walk(_row(trailing: 3));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('disabling it closes it, focus on the row', (tester) async {
        final content = await mountLive(tester, _row());
        final origin = _originOf(tester);

        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(2));

        content.value = _walk(_row(enabled: false));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_focused(tester), 'SwipeActions');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(Button), findsNothing);
        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('a row that already holds focus keeps it when it is disabled '
          'or left with nothing to swipe', (tester) async {
        final content = await mountLive(tester, _row());

        // Focus on an action, then back on the row by the key that closes it.
        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        await _key(tester, LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(_focused(tester), 'SwipeActions');

        content.value = _walk(_row(enabled: false));
        await tester.pumpAndSettle();
        expect(_focused(tester), 'SwipeActions', reason: 'disabled');

        content.value = _walk(_row(trailing: 0));
        await tester.pumpAndSettle();
        expect(_focused(tester), 'SwipeActions', reason: 'no actions at all');
        expect(tester.takeException(), isNull);
      });

      testWidgets('focus that is not on an action is left where it is', (
        tester,
      ) async {
        final content = await mountLive(
          tester,
          _row(child: _focusableRow()),
        );
        final origin = _originOf(tester);

        // A pointer opens the row and does not move focus: it stays before
        // the row while the rebuild closes it.
        expect(_focused(tester), 'start');
        await _openTrailing(tester, origin);
        expect(_offsetOf(tester, origin), -_extent(2));
        content.value = _walk(_row(trailing: 3, child: _focusableRow()));
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), 0, reason: 'the row closed');
        expect(_focused(tester), 'start', reason: 'before the row');

        // On the row's own content.
        expect(await _tabs(tester, 1), ['content']);
        await _openTrailing(tester, origin, count: 3);
        content.value = _walk(_row(trailing: 1, child: _focusableRow()));
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), 0, reason: 'the row closed');
        expect(_focused(tester), 'content', reason: "the row's own content");

        // The same, when the row can no longer be swiped.
        await _openTrailing(tester, origin, count: 1);
        content.value = _walk(_row(enabled: false, child: _focusableRow()));
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), 0, reason: 'the row closed');
        expect(_focused(tester), 'content', reason: 'a disabled row');
        expect(tester.takeException(), isNull);
      });

      testWidgets('a rebuild that changes neither the number of actions nor '
          'whether the row can be swiped leaves focus on its action', (
        tester,
      ) async {
        final content = await mountLive(tester, _row());
        final origin = _originOf(tester);
        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(2));

        // The actions change, but not in number.
        content.value = _walk(_row(destructiveTrailing: {0}));
        await tester.pumpAndSettle();

        expect(_focused(tester), 'T1');
        expect(_offsetOf(tester, origin), -_extent(2), reason: 'still open');
        expect(tester.takeException(), isNull);
      });

      testWidgets('a pull that closes the row takes focus off the hidden '
          'action once it rests', (tester) async {
        await mount(tester, _row());
        final origin = _originOf(tester);

        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(2));

        // A pointer does not move focus in Flutter, so nothing else would.
        final stroke = await _slowPull(
          tester,
          origin + const Offset(100, 36),
          150,
        );
        await _lift(tester, stroke);
        await tester.pumpAndSettle();

        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('a tap on the open row takes focus off the hidden action as '
          'it starts to close', (tester) async {
        await mount(tester, _row());
        final origin = _originOf(tester);

        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(2));

        // A pointer does not move focus in Flutter: the row does, the moment
        // it is told to close, not once it has finished.
        await tester.tapAt(origin + const Offset(100, 36));
        await tester.pump();
        expect(_offsetOf(tester, origin), lessThan(0), reason: 'on its way');
        expect(_focused(tester), 'SwipeActions');

        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('another row of the scope starting to move takes focus off '
          'the hidden action as this one starts to close', (tester) async {
        const rowA = Key('rowA');
        await mount(
          tester,
          SwipeActionScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _scroller(
                  SizedBox(
                    width: _kRowWidth,
                    height: _kRowHeight,
                    child: SwipeActions(
                      key: rowA,
                      leadingActions: _actions('L', 2),
                      child: _plainRow(key: const Key('a')),
                    ),
                  ),
                ),
                _scroller(
                  SizedBox(
                    width: _kRowWidth,
                    height: _kRowHeight,
                    child: SwipeActions(
                      trailingActions: _actions('T', 2),
                      child: _plainRow(key: const Key('b')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        final a = tester.getTopLeft(find.byKey(const Key('a')));
        final b = tester.getTopLeft(find.byKey(const Key('b')));
        double offsetOfA() =>
            tester.getTopLeft(find.byKey(const Key('a'))).dx - a.dx;
        Key? rowWithFocus() => FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<SwipeActions>()
            ?.key;

        expect(await _tabs(tester, 1), ['L0']);
        await tester.pumpAndSettle();
        expect(offsetOfA(), _extent(2));

        // The other row is pulled; this one is told to close, and its action
        // is clipped away. The pull has only just armed: A is on its way.
        final stroke = await _pull(
          tester,
          b + const Offset(300, 36),
          -20,
          over: _kFrame,
        );
        expect(offsetOfA(), greaterThan(0), reason: 'on its way');
        expect(_focused(tester), 'SwipeActions');
        expect(rowWithFocus(), rowA, reason: 'the row that was closed');

        await _lift(tester, stroke);
        await tester.pumpAndSettle();
        expect(offsetOfA(), 0);
        expect(rowWithFocus(), rowA, reason: 'and the other took none');
      });

      testWidgets('another reading direction closes it and takes focus off the '
          'hidden action', (tester) async {
        await mount(tester, _row());
        final origin = _originOf(tester);

        expect(await _tabs(tester, 1), ['T1']);
        await tester.pumpAndSettle();
        expect(_offsetOf(tester, origin), -_extent(2));

        await pumpTestApp(
          tester,
          _walk(_row()),
          textDirection: TextDirection.rtl,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(_offsetOf(tester, origin), 0);
        expect(_focused(tester), 'SwipeActions');
      });

      testWidgets('an action disabled under focus leaves the row open', (
        tester,
      ) async {
        final content = await mountLive(tester, _row());
        final origin = _originOf(tester);

        expect(await _tabs(tester, 2), ['T1', 'T0']);
        await tester.pumpAndSettle();

        // Same number of actions, so the row has nowhere else to be.
        content.value = _walk(_row(disabledTrailing: {0}));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_offsetOf(tester, origin), -_extent(2));
      });
    });
  });

  group('SwipeActionScope', () {
    Widget scoped(List<Widget> rows, {bool scope = true}) {
      final column = Column(mainAxisSize: MainAxisSize.min, children: rows);

      return scope ? SwipeActionScope(child: column) : column;
    }

    Widget keyedRow(String name, {List<String>? log}) => _scroller(
      SizedBox(
        width: _kRowWidth,
        height: _kRowHeight,
        child: SwipeActions(
          trailingActions: _actions(name, 2, log: log),
          child: _plainRow(key: Key(name)),
        ),
      ),
    );

    testWidgets('opening a row closes the one that was open', (tester) async {
      await _pump(tester, scoped([keyedRow('a'), keyedRow('b')]));
      final a = tester.getTopLeft(find.byKey(const Key('a')));
      final b = tester.getTopLeft(find.byKey(const Key('b')));

      await _openBy(tester, a, -(_extent(2) + 40));
      expect(_offsetOf(tester, a, const Key('a')), -_extent(2));

      // B starts to move: A is told to close, and does.
      final stroke = await _slowPull(tester, b + const Offset(300, 36), -60);
      await tester.pumpAndSettle();
      expect(_offsetOf(tester, a, const Key('a')), 0);
      expect(_offsetOf(tester, b, const Key('b')), isNegative);

      await _lift(tester, stroke);
      await tester.pumpAndSettle();
    });

    testWidgets('the row that moves last keeps the claim, and only it', (
      tester,
    ) async {
      late CoreSwipeExclusivity exclusivity;
      await _pump(
        tester,
        SwipeActionScope(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  exclusivity = SwipeActionScope.maybeOf(context)!;

                  return keyedRow('a');
                },
              ),
              keyedRow('b'),
            ],
          ),
        ),
      );
      final a = tester.getTopLeft(find.byKey(const Key('a')));
      final b = tester.getTopLeft(find.byKey(const Key('b')));
      expect(exclusivity.holder, isNull);

      await _openBy(tester, a, -(_extent(2) + 40));
      final held = exclusivity.holder;
      expect(held, isNotNull, reason: 'an open row holds the scope');

      // A tap closes the open row; once it rests closed it lets go.
      await tester.tapAt(a + const Offset(100, 36));
      await tester.pumpAndSettle();
      expect(exclusivity.holder, isNull);

      // A row mid-drag holds it, before it has opened at all.
      final stroke = await _pull(tester, b + const Offset(300, 36), -80);
      expect(exclusivity.holder, isNotNull);
      expect(exclusivity.holder, isNot(held));
      await _lift(tester, stroke);
      await tester.pumpAndSettle();
      expect(exclusivity.holder, isNotNull, reason: 'it settled open');
    });

    testWidgets('a row that is taken out lets go of the scope', (tester) async {
      late CoreSwipeExclusivity exclusivity;
      Widget tree({required bool withRow}) => SwipeActionScope(
        child: Builder(
          builder: (context) {
            exclusivity = SwipeActionScope.maybeOf(context)!;

            return withRow ? keyedRow('a') : const SizedBox();
          },
        ),
      );
      final content = await _pumpLive(tester, tree(withRow: true));
      final a = tester.getTopLeft(find.byKey(const Key('a')));
      await _openBy(tester, a, -(_extent(2) + 40));
      expect(exclusivity.holder, isNotNull);

      content.value = tree(withRow: false);
      await tester.pump();

      expect(find.byType(SwipeActions), findsNothing);
      expect(exclusivity.holder, isNull);
    });

    testWidgets('without a scope the rows are independent', (tester) async {
      await _pump(
        tester,
        scoped([keyedRow('a'), keyedRow('b')], scope: false),
      );
      final a = tester.getTopLeft(find.byKey(const Key('a')));
      final b = tester.getTopLeft(find.byKey(const Key('b')));

      await _openBy(tester, a, -(_extent(2) + 40));
      await _openBy(tester, b, -(_extent(2) + 40));

      expect(_offsetOf(tester, a, const Key('a')), -_extent(2));
      expect(_offsetOf(tester, b, const Key('b')), -_extent(2));
    });

    testWidgets('there is no scope until one is mounted', (tester) async {
      CoreSwipeExclusivity? seen;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            seen = SwipeActionScope.maybeOf(context);

            return const SizedBox();
          },
        ),
      );

      expect(seen, isNull);
    });

    testWidgets('the nearest scope is the one a row joins', (tester) async {
      late CoreSwipeExclusivity outer;
      late CoreSwipeExclusivity inner;
      await _pump(
        tester,
        SwipeActionScope(
          child: Builder(
            builder: (context) {
              outer = SwipeActionScope.maybeOf(context)!;

              return SwipeActionScope(
                child: Builder(
                  builder: (context) {
                    inner = SwipeActionScope.maybeOf(context)!;

                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(inner, isNot(same(outer)));
    });
  });

  group('SwipeActions style', () {
    Future<ResolvedSwipeActions> resolve(
      WidgetTester tester, {
      CoreDensity density = CoreDensity.defaultDensity,
      double scaling = 1,
      CoreComponentTheme? componentTheme,
      CoreSwipeActionsStyle? style,
      bool disableAnimations = false,
      int leading = 2,
      int trailing = 1,
    }) async {
      late ResolvedSwipeActions resolved;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveSwipeActions(
              context,
              leadingCount: leading,
              trailingCount: trailing,
              swipeActionsStyle: style,
            );

            return const SizedBox();
          },
        ),
        theme: ThemeData(scaling: scaling),
        density: density,
        componentTheme: componentTheme,
        disableAnimations: disableAnimations,
      );

      return resolved;
    }

    testWidgets('the defaults are the Core defaults', (tester) async {
      final resolved = await resolve(tester);

      expect(resolved.actionWidth, CoreSwipeActionsStyle.defaultActionWidth);
      expect(
        resolved.actionSpacing,
        CoreSwipeActionsStyle.defaultActionSpacing,
      );
      expect(resolved.platterInset, CoreSwipeActionsStyle.defaultPlatterInset);
      expect(resolved.leadingExtent, 132);
      expect(resolved.trailingExtent, 72);
      expect(resolved.platterColor, isNull);
      expect(resolved.fullSwipeScale, 1);
      expect(
        resolved.settleDuration,
        CoreSwipeActionsContract.defaultSettleDuration,
      );
      expect(
        resolved.labelGapStyle,
        CoreSwipeActionsStyle.defaultLabelGapStyle,
      );
      expect(
        resolved.actionButtonStyle,
        isNull,
        reason: 'the button owns its chrome: nothing stated, nothing forwarded',
      );
    });

    testWidgets('the cell is a control row and the gaps are spacing, so '
        'density moves them', (tester) async {
      final compact = await resolve(tester, density: CoreDensity.compact);
      final spacious = await resolve(tester, density: CoreDensity.spacious);

      expect(compact.actionWidth, lessThan(48));
      expect(compact.actionSpacing, lessThan(12));
      expect(compact.platterInset, lessThan(12));
      expect(spacious.actionWidth, greaterThan(48));
      expect(spacious.actionSpacing, greaterThan(12));
      expect(spacious.platterInset, greaterThan(12));
      // The extent is the platter's width at that density, by construction.
      expect(
        compact.leadingExtent,
        CoreSwipeActionsStyle.extentFor(
          2,
          actionWidth: compact.actionWidth,
          actionSpacing: compact.actionSpacing,
          platterInset: compact.platterInset,
        ),
      );
    });

    testWidgets('scaling multiplies every length', (tester) async {
      final scaled = await resolve(tester, scaling: 1.25);

      expect(scaled.actionWidth, 60);
      expect(scaled.actionSpacing, 15);
      expect(scaled.platterInset, 15);
      expect(scaled.leadingExtent, 165);
      expect(scaled.trailingExtent, 90);
    });

    testWidgets('the row opens exactly as far as the platter is wide, at any '
        'density and scaling', (tester) async {
      for (final (density, scaling) in [
        (CoreDensity.compact, 1.0),
        (CoreDensity.spacious, 1.0),
        (CoreDensity.defaultDensity, 1.25),
      ]) {
        await _pump(
          tester,
          Builder(
            builder: (context) => _row(),
          ),
          theme: ThemeData(scaling: scaling),
          density: density,
        );
        final resolved = await resolve(
          tester,
          density: density,
          scaling: scaling,
          trailing: 2,
        );
        await _pump(
          tester,
          _row(),
          theme: ThemeData(scaling: scaling),
          density: density,
        );
        final origin = _originOf(tester);
        await _openBy(tester, origin, -(resolved.trailingExtent + 40));

        expect(
          _offsetOf(tester, origin),
          closeTo(-resolved.trailingExtent, 1e-6),
          reason: '$density at ${scaling}x',
        );
        expect(
          tester.getRect(find.byType(PositionedDirectional)).width,
          closeTo(resolved.trailingExtent, 1e-6),
        );
      }
    });

    testWidgets('the theme restyles every row, the instance restyles one', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        swipeActions: CoreSwipeActionsTheme(
          style: CoreSwipeActionsStyle(actionWidth: 56, actionSpacing: 20),
        ),
      );

      var resolved = await resolve(tester, componentTheme: theme);
      expect(resolved.actionWidth, 56);
      expect(resolved.actionSpacing, 20);
      expect(resolved.platterInset, 12, reason: 'the default stays');

      resolved = await resolve(
        tester,
        componentTheme: theme,
        style: const CoreSwipeActionsStyle(actionWidth: 64, platterInset: 8),
      );
      expect(resolved.actionWidth, 64, reason: 'the instance wins');
      expect(resolved.actionSpacing, 20, reason: 'the theme still holds');
      expect(resolved.platterInset, 8);
    });

    testWidgets('a nested slot is merged field by field, not replaced', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        swipeActions: CoreSwipeActionsTheme(
          style: CoreSwipeActionsStyle(
            labelGapStyle: CoreGapStyle(size: 8),
          ),
        ),
      );

      final resolved = await resolve(tester, componentTheme: theme);

      expect(resolved.labelGapStyle.size, 8);
    });

    testWidgets('the button style merges theme and instance, field by field', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        swipeActions: CoreSwipeActionsTheme(
          style: CoreSwipeActionsStyle(
            actionButtonStyle: CoreButtonStyle(borderWidth: 2, width: 52),
          ),
        ),
      );

      final themed = await resolve(tester, componentTheme: theme);
      expect(themed.actionButtonStyle?.borderWidth, 2);
      expect(themed.actionButtonStyle?.width, 52);

      final both = await resolve(
        tester,
        componentTheme: theme,
        style: const CoreSwipeActionsStyle(
          actionButtonStyle: CoreButtonStyle(width: 60),
        ),
      );
      expect(both.actionButtonStyle?.width, 60, reason: 'the instance wins');
      expect(both.actionButtonStyle?.borderWidth, 2, reason: 'the theme holds');
    });

    testWidgets('the style reaches the screen', (tester) async {
      await _pump(
        tester,
        _row(
          style: const CoreSwipeActionsStyle(
            actionWidth: 56,
            actionSpacing: 20,
            platterInset: 8,
            labelGapStyle: CoreGapStyle(size: 10),
          ),
        ),
      );
      final origin = _originOf(tester);
      final extent = CoreSwipeActionsStyle.extentFor(
        2,
        actionWidth: 56,
        actionSpacing: 20,
        platterInset: 8,
      );
      await _openBy(tester, origin, -(extent + 40));

      expect(_offsetOf(tester, origin), -extent);
      // T0 outermost: 8 in from the edge, a 56 cell, its button centred.
      expect(
        _centerX(tester, 'T0') - origin.dx,
        closeTo(_kRowWidth - 8 - 56 / 2, 1e-6),
      );
      expect(
        _centerX(tester, 'T1') - origin.dx,
        closeTo(_kRowWidth - 8 - 56 - 20 - 56 / 2, 1e-6),
      );
      final button = tester.getRect(_cellButton('T0'));
      expect(tester.getRect(find.text('T0')).top, button.bottom + 10);
    });

    testWidgets('the button style is forwarded raw to every button', (
      tester,
    ) async {
      const buttonStyle = CoreButtonStyle(borderWidth: 3);
      await _pump(
        tester,
        _row(
          style: const CoreSwipeActionsStyle(actionButtonStyle: buttonStyle),
        ),
      );
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      for (final tag in ['T0', 'T1']) {
        expect(
          tester.widget<Button>(_cellButton(tag)).buttonStyle,
          buttonStyle,
          reason: 'the stated slot reaches each button unchanged',
        );
      }
    });

    testWidgets('a button style nobody stated forwards nothing', (
      tester,
    ) async {
      await _pump(tester, _row());
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      for (final tag in ['T0', 'T1']) {
        expect(tester.widget<Button>(_cellButton(tag)).buttonStyle, isNull);
      }
    });

    testWidgets('the label style is the theme-resolved type and colour', (
      tester,
    ) async {
      await _pump(
        tester,
        _row(
          style: const CoreSwipeActionsStyle(
            labelStyle: CoreTextStyle(fontWeight: 700),
          ),
        ),
      );
      final origin = _originOf(tester);
      await _openTrailing(tester, origin);

      final style = tester.widget<Text>(find.text('T0')).style!;
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, isNotNull);
    });
  });

  group('SwipeActions API', () {
    test('the threshold is a fraction of the row', () {
      expect(
        () => SwipeActions(fullSwipeThreshold: 0, child: const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => SwipeActions(fullSwipeThreshold: 1.01, child: const SizedBox()),
        throwsAssertionError,
      );
      expect(
        const SwipeActions(fullSwipeThreshold: 1, child: SizedBox()),
        isA<SwipeActions>(),
      );
    });

    test('the defaults are the Contract defaults', () {
      const swipe = SwipeActions(child: SizedBox());

      expect(swipe.leadingActions, isEmpty);
      expect(swipe.trailingActions, isEmpty);
      expect(
        swipe.allowsFullSwipe,
        CoreSwipeActionsContract.defaultAllowsFullSwipe,
      );
      expect(
        swipe.fullSwipeThreshold,
        CoreSwipeActionsContract.defaultFullSwipeThreshold,
      );
      expect(swipe.showLabels, CoreSwipeActionsContract.defaultShowLabels);
      expect(swipe.enabled, isNull);
      expect(swipe.swipeActionsStyle, isNull);
    });

    test('copyWith replaces what it is given and keeps the rest', () {
      final action = _actions('T', 1);
      const child = SizedBox(key: Key('child'));
      final swipe = SwipeActions(
        key: const Key('swipe'),
        leadingActions: action,
        trailingActions: action,
        allowsFullSwipe: false,
        fullSwipeThreshold: 0.5,
        showLabels: false,
        enabled: false,
        swipeActionsStyle: const CoreSwipeActionsStyle(actionWidth: 56),
        child: child,
      );

      final same = swipe.copyWith();
      expect(same.key, swipe.key);
      expect(same.leadingActions, swipe.leadingActions);
      expect(same.trailingActions, swipe.trailingActions);
      expect(same.allowsFullSwipe, false);
      expect(same.fullSwipeThreshold, 0.5);
      expect(same.showLabels, false);
      expect(same.enabled, false);
      expect(same.swipeActionsStyle, swipe.swipeActionsStyle);
      expect(same.child, child);

      final other = swipe.copyWith(
        key: const Key('other'),
        leadingActions: const [],
        allowsFullSwipe: true,
        fullSwipeThreshold: 0.9,
        showLabels: true,
        enabled: true,
        child: const SizedBox(key: Key('other-child')),
      );
      expect(other.key, const Key('other'));
      expect(other.leadingActions, isEmpty);
      expect(other.trailingActions, swipe.trailingActions);
      expect(other.allowsFullSwipe, true);
      expect(other.fullSwipeThreshold, 0.9);
      expect(other.showLabels, true);
      expect(other.enabled, true);
      expect(other.child, isNot(child));
    });

    test('withStyle merges a patch into the style, patch winning', () {
      const base = SwipeActions(
        swipeActionsStyle: CoreSwipeActionsStyle(
          actionWidth: 56,
          actionSpacing: 8,
        ),
        child: SizedBox(),
      );

      final patched = base.withStyle(
        const CoreSwipeActionsStyle(actionSpacing: 20, platterInset: 4),
      );

      expect(
        patched.swipeActionsStyle,
        const CoreSwipeActionsStyle(
          actionWidth: 56,
          actionSpacing: 20,
          platterInset: 4,
        ),
      );
      expect(
        const SwipeActions(child: SizedBox())
            .withStyle(const CoreSwipeActionsStyle(actionWidth: 40))
            .swipeActionsStyle,
        const CoreSwipeActionsStyle(actionWidth: 40),
      );
    });

    testWidgets('a patched widget renders with the patch', (tester) async {
      final swipe = SwipeActions(
        trailingActions: _actions('T', 2),
        child: _plainRow(),
      ).withStyle(const CoreSwipeActionsStyle(platterInset: 4));
      await _pump(
        tester,
        SizedBox(width: _kRowWidth, height: _kRowHeight, child: swipe),
      );
      final origin = _originOf(tester);
      final extent = CoreSwipeActionsStyle.extentFor(
        2,
        actionWidth: 48,
        actionSpacing: 12,
        platterInset: 4,
      );
      await _openBy(tester, origin, -(extent + 40));

      expect(_offsetOf(tester, origin), -extent);
    });
  });
}
