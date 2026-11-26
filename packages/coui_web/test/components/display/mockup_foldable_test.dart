// The Web `MockupFoldable` as a component: where the content lives at an
// angle, what it is told about the fold, and what a change of angle does.
//
// The resolver's own output is covered by `mockup_foldable_style_test.dart`
// and the markup a browser receives by `mockup_foldable_ssr_test.dart`. What
// is left is what only a mounted component has: one subtree of content that
// moves between two screens without being built anew, a `FoldScope` around
// it, and a State that draws the angle a move has reached.
//
// The VM has no frames, so every change of angle here is a jump — which is
// also what a server and a reader who asked for reduced motion get. The
// frames of a real move are stepped by hand in
// `mockup_foldable_motion_test.dart` and seen in Chrome.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// What every build of [_Reader] read, in the order it was built.
final List<({CoreFoldLayout layout, CoreTextDirection direction})> _read = [];

/// Content that reads the fold of the screen it is on.
class _Reader extends StatelessComponent {
  const _Reader();

  @override
  Component build(BuildContext context) {
    _read.add((
      layout: FoldScope.of(context),
      direction: context
          .dependOnInheritedComponentOfExactType<FoldLayoutScope>()!
          .direction,
    ));

    return const div([], classes: 'reader');
  }
}

/// Every [_Counter] state created, in order, so a test can tell the content
/// that moved from one that was built anew.
final List<_CounterState> _counters = [];

/// Content with something to lose: a count it holds itself.
class _Counter extends StatefulComponent {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    _counters.add(this);
  }

  void increment() => setState(() => count++);

  @override
  Component build(BuildContext context) =>
      div([Text('$count')], classes: 'counter');
}

/// The page around the device: it holds the angle, and hands the device the
/// same content component every time it rebuilds.
class _Host extends StatefulComponent {
  const _Host({
    required this.angle,
    required this.child,
    this.style,
    this.showCamera = CoreMockupFoldableContract.defaultShowCamera,
    this.showStatus = CoreMockupFoldableContract.defaultShowStatus,
  });

  final double angle;
  final Component child;
  final CoreMockupFoldableStyle? style;
  final bool showCamera;
  final bool showStatus;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  static late _HostState current;

  late double _angle = component.angle;
  late CoreMockupFoldableStyle? _style = component.style;
  late bool _showCamera = component.showCamera;
  late bool _showStatus = component.showStatus;

  @override
  void initState() {
    super.initState();
    current = this;
  }

  void fold(double angle) => setState(() => _angle = angle);

  void restyle(CoreMockupFoldableStyle? style) =>
      setState(() => _style = style);

  void show({bool? camera, bool? status}) => setState(() {
    _showCamera = camera ?? _showCamera;
    _showStatus = status ?? _showStatus;
  });

  @override
  Component build(BuildContext context) => MockupFoldable(
    id: 'fold',
    foldAngle: _angle,
    showCamera: _showCamera,
    showStatus: _showStatus,
    mockupFoldableStyle: _style,
    child: component.child,
  );
}

Future<void> _pump(
  ComponentTester tester,
  double angle, {
  required Component child,
  CoreMockupFoldableStyle? style,
  bool showCamera = CoreMockupFoldableContract.defaultShowCamera,
  bool showStatus = CoreMockupFoldableContract.defaultShowStatus,
  CoreTextDirection direction = CoreTextDirection.ltr,
}) async {
  tester.pumpComponent(
    Theme.defaults(
      child: FoldLayoutScope(
        layout: CoreFoldLayout.unmeasured,
        direction: direction,
        child: _Host(
          angle: angle,
          style: style,
          showCamera: showCamera,
          showStatus: showStatus,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _fold(ComponentTester tester, double angle) async {
  _HostState.current.fold(angle);
  await tester.pump();
}

/// The DOM children of [element]: the nearest elements below it that draw a
/// box, whatever components stand between.
List<DomElement> _domChildren(Element element) {
  final found = <DomElement>[];
  void visit(Element child) {
    if (child is DomElement) {
      found.add(child);

      return;
    }
    child.visitChildren(visit);
  }

  element.visitChildren(visit);

  return found;
}

/// The device's root and its six parts, back to front.
({
  DomElement root,
  DomElement live,
  DomElement rightHalf,
  DomElement rightEdge,
  DomElement leftHalf,
  DomElement leftEdge,
  DomElement cover,
})
_device() {
  final root =
      find
              .byComponentPredicate(
                (c) => c is DomComponent && c.id == 'fold',
              )
              .evaluate()
              .single
          as DomElement;
  final parts = _domChildren(root);
  expect(parts, hasLength(6));

  return (
    root: root,
    live: parts.first,
    rightHalf: parts[1],
    rightEdge: parts[2],
    leftHalf: parts[3],
    leftEdge: parts[4],
    cover: parts[5],
  );
}

bool _has(DomElement element, String className) =>
    (element.component.classes ?? '').split(' ').contains(className);

/// What [half] shows: the one box inside it, which cuts it at the hinge.
DomElement _cutOf(DomElement half) => _domChildren(half).single;

String? _transform(DomElement element) =>
    element.component.styles?.properties['transform'];

/// Whether [element] is below [ancestor].
bool _isUnder(Element element, Element ancestor) {
  var under = false;
  element.visitAncestorElements((parent) {
    if (parent == ancestor) under = true;

    return !under;
  });

  return under;
}

/// The element of the first build of the counter — the content that moves.
Element get _original => _counters.first.context as Element;

/// Every element under [element] that draws a box, in document order.
List<DomElement> _boxesUnder(Element element) {
  final found = <DomElement>[];
  void visit(Element child) {
    if (child is DomElement) found.add(child);
    child.visitChildren(visit);
  }

  element.visitChildren(visit);

  return found;
}

/// The status islands drawn under [element]: the layer over a screen that
/// takes no pointer and is kept from assistive technology.
List<DomElement> _islandsUnder(Element element) => [
  for (final box in _boxesUnder(element))
    if (box.component.attributes?['aria-hidden'] == 'true' &&
        _has(box, 'pointer-events-none') &&
        _has(box, 'inset-0'))
      box,
];

/// The boxes around [element], nearest first.
List<DomElement> _boxesAround(Element element) {
  final found = <DomElement>[];
  element.visitAncestorElements((parent) {
    if (parent is DomElement) found.add(parent);

    return true;
  });

  return found;
}

/// The bodies the device is made of, as it handed them to the tree.
List<MockupDevice> _bodies() => [
  for (final element in find.byType(MockupDevice).evaluate())
    element.component as MockupDevice,
];

void main() {
  setUp(() {
    _read.clear();
    _counters.clear();
  });

  group('MockupFoldable — what the content reads of the fold', () {
    testComponents('open flat: one fold down the middle of the inner '
        'screen, lying flat, and the screen is one segment', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Reader());

      // Drawn as it is: built once.
      expect(_read, hasLength(1));
      final layout = _read.single.layout;
      final fold = layout.folds.single;
      expect(fold.state, CoreFoldState.flat);
      expect(fold.bounds.left, layout.width / 2);
      expect(fold.bounds.width, 0);
      expect(layout.segments, hasLength(1));
      expect(layout.isSplit, isFalse);
      expect(layout.posture, CoreFoldPosture.flat);
      // The open body is wider than tall.
      expect(layout.width, greaterThan(layout.height));
    });

    testComponents('held like a book: the fold is half opened and the screen '
        'is two segments — on the hidden original and on both copies', (
      tester,
    ) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const _Reader());

      // The original and one build per half.
      expect(_read, hasLength(3));
      for (final seen in _read) {
        expect(seen.layout, _read.first.layout);
        expect(seen.layout.folds.single.state, CoreFoldState.halfOpened);
        expect(seen.layout.segments, hasLength(2));
        expect(seen.layout.isSplit, isTrue);
        expect(seen.layout.posture, CoreFoldPosture.book);
        expect(seen.layout.kind, CoreFoldableKind.fold);
      }
      final segments = _read.first.layout.segments;
      expect(segments.first.width, _read.first.layout.width / 2);
      expect(segments.last.left, _read.first.layout.width / 2);
    });

    testComponents('shut: the content is on the cover, a screen with no '
        'fold, taller than wide', (tester) async {
      await _pump(tester, CoreMockupFold.closed, child: const _Reader());

      expect(_read, hasLength(1));
      final layout = _read.single.layout;
      expect(layout.folds, isEmpty);
      expect(layout.segments, hasLength(1));
      expect(layout.kind, isNull);
      expect(layout.posture, isNull);
      expect(layout.height, greaterThan(layout.width));
    });

    testComponents('folding tells the content, at the angle the rule gives', (
      tester,
    ) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Reader());
      final open = _read.last.layout;

      // Still flat to the app above the rule's angle…
      await _fold(tester, CoreMockupFold.flatFrom);
      expect(_read.last.layout.folds.single.state, CoreFoldState.flat);
      // …half opened below it…
      await _fold(tester, CoreMockupFold.flatFrom - 1);
      expect(_read.last.layout.folds.single.state, CoreFoldState.halfOpened);
      expect(_read.last.layout.width, open.width);
      // …and on the cover once it is nearly shut.
      await _fold(tester, CoreMockupFold.coverUntil);
      expect(_read.last.layout.folds, isEmpty);
      expect(_read.last.layout.width, lessThan(open.width));
    });

    testComponents('the content keeps reading in the direction the page '
        'reads in, on either screen', (tester) async {
      await _pump(
        tester,
        CoreMockupFold.halfOpen,
        child: const _Reader(),
        direction: CoreTextDirection.rtl,
      );
      expect(_read.map((seen) => seen.direction).toSet(), {
        CoreTextDirection.rtl,
      });

      _read.clear();
      await _fold(tester, CoreMockupFold.closed);
      expect(_read.map((seen) => seen.direction).toSet(), {
        CoreTextDirection.rtl,
      });
    });
  });

  group('MockupFoldable — one subtree of content, on the screen that '
      'carries it', () {
    testComponents('open flat it is in the open body, built once', (
      tester,
    ) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Counter());
      final device = _device();

      expect(_counters, hasLength(1));
      expect(_isUnder(_original, device.live), isTrue);
      // Shown, and within reach.
      expect(_has(device.live, 'invisible'), isFalse);
      expect(device.live.component.attributes, isNull);
      // No half is drawn: the body is drawn as it is, and each half's cut
      // holds nothing.
      expect(_domChildren(_cutOf(device.rightHalf)), isEmpty);
      expect(_domChildren(_cutOf(device.leftHalf)), isEmpty);
    });

    testComponents('bent, the original is hidden and out of reach, and each '
        'half holds a second build of it that takes no input', (tester) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const _Counter());
      final device = _device();

      expect(_counters, hasLength(3));
      // The original: still mounted in the open body, hidden and inert.
      expect(_isUnder(_original, device.live), isTrue);
      expect(_has(device.live, 'invisible'), isTrue);
      expect(device.live.component.attributes, {'inert': ''});
      // One copy per half.
      expect(
        _isUnder(_counters[1].context as Element, device.rightHalf),
        isTrue,
      );
      expect(
        _isUnder(_counters[2].context as Element, device.leftHalf),
        isTrue,
      );
      for (final half in [device.rightHalf, device.leftHalf]) {
        expect(half.component.attributes, {
          'inert': '',
          'aria-hidden': 'true',
        });
        // Cut at the hinge by the box inside it, not by itself — a clip of
        // the turned element's own is drawn soft on a dense screen.
        final cut = _cutOf(half);
        expect(half.component.styles?.properties['clip-path'], isNull);
        expect(cut.component.styles?.properties['clip-path'], isNotNull);
        expect(cut.component.styles?.properties['transform'], isNull);
        // The body, the dark of a screen going off, the shade.
        expect(_domChildren(cut), hasLength(3));
      }
    });

    testComponents('the halves are out of reach at every angle, so nothing '
        'about them changes when a copy arrives', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Counter());

      for (final half in [_device().rightHalf, _device().leftHalf]) {
        expect(half.component.attributes, {
          'inert': '',
          'aria-hidden': 'true',
        });
      }
    });

    testComponents('shut it is on the cover, built once, and the open body '
        'holds none', (tester) async {
      await _pump(tester, CoreMockupFold.closed, child: const _Counter());
      final device = _device();

      expect(_counters, hasLength(1));
      expect(_isUnder(_original, device.cover), isTrue);
      expect(_isUnder(_original, device.live), isFalse);
      // The cover faces the viewer and takes input.
      expect(_has(device.cover, 'hidden'), isFalse);
      expect(device.cover.component.attributes, isNull);
    });

    testComponents('it keeps what it holds as it moves from the inner '
        'screen to the cover and back', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Counter());
      final original = _counters.single
        ..increment()
        ..increment();
      await tester.pump();

      // Shut: the same state, now under the cover — nothing was built anew.
      await _fold(tester, CoreMockupFold.closed);
      expect(_counters, hasLength(1));
      expect(original.mounted, isTrue);
      expect(original.count, 2);
      expect(_isUnder(_original, _device().cover), isTrue);

      // Held like a book: back in the open body, and a fresh build per half.
      await _fold(tester, CoreMockupFold.halfOpen);
      expect(original.mounted, isTrue);
      expect(original.count, 2);
      expect(_isUnder(_original, _device().live), isTrue);
      expect(_counters, hasLength(3));
      expect(_counters[1].count, 0);
      expect(_counters[2].count, 0);

      // Open flat: the copies are gone and the original is what is shown.
      await _fold(tester, CoreMockupFold.flat);
      expect(original.mounted, isTrue);
      expect(original.count, 2);
      expect(_counters[1].mounted, isFalse);
      expect(_counters[2].mounted, isFalse);
      expect(find.text('2'), findsOneComponent);
    });

    testComponents('it is the same subtree however many times the device '
        'is folded and opened', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Counter());
      final original = _counters.single..increment();
      await tester.pump();

      // Jumps and steps through the bent range, across the screen change in
      // both directions, more than once: a subtree that has moved before is
      // moved again, and replaced by nothing where it was.
      for (final angle in [
        0.0,
        180.0,
        0.0,
        144.0,
        20.0,
        60.0,
        29.0,
        31.0,
        0.0,
        180.0,
      ]) {
        await _fold(tester, angle);
        final device = _device();
        final onCover = angle <= CoreMockupFold.coverUntil;

        expect(original.mounted, isTrue, reason: '$angle°');
        expect(original.count, 1, reason: '$angle°');
        expect(
          _isUnder(_original, onCover ? device.cover : device.live),
          isTrue,
          reason: '$angle° — the content is on the screen that carries it',
        );
        expect(
          _isUnder(_original, onCover ? device.live : device.cover),
          isFalse,
          reason: '$angle°',
        );
        // The original, and one build per half while the inner screen is
        // bent and carries the content — nothing else is alive.
        final copies = !onCover && angle < CoreMockupFold.flat ? 2 : 0;
        expect(
          _counters.where((counter) => counter.mounted),
          hasLength(1 + copies),
          reason: '$angle°',
        );
        expect(
          find.byType(_Counter),
          findsNComponents(1 + copies),
          reason: '$angle°',
        );
      }
    });

    testComponents('while the cover carries it, the halves draw the open '
        'body with a dark screen and no content', (tester) async {
      await _pump(tester, 20, child: const _Counter());
      final device = _device();

      expect(_counters, hasLength(1));
      expect(_isUnder(_original, device.cover), isTrue);
      // The copies are still the body — just nothing on its screen.
      expect(_domChildren(_cutOf(device.rightHalf)), hasLength(3));
    });
  });

  group('MockupFoldable — the bodies', () {
    testComponents('both faces are MockupDevices: a tablet on its side with '
        'no camera, and a phone half as wide', (tester) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const div([]));
      final bodies = _bodies();
      final inner = bodies
          .where((face) => face.device == CoreMockupFoldableLayout.innerDevice)
          .toList();
      final cover = bodies
          .where((face) => face.device == CoreMockupFoldableLayout.coverDevice)
          .toList();

      // The open body and its two copies, and the cover.
      expect(inner, hasLength(3));
      expect(cover, hasLength(1));
      for (final body in inner) {
        expect(body.orientation, CoreMockupFoldableLayout.innerOrientation);
        expect(body.width, CoreMockupFoldableStyle.defaultWidth);
        expect(body.finish, CoreMockupDeviceFinish.realistic);
      }
      expect(
        cover.single.orientation,
        CoreMockupFoldableLayout.coverOrientation,
      );
      expect(cover.single.width, CoreMockupFoldableStyle.defaultWidth / 2);
      // No body draws a camera or a status bar of its own: what this device
      // shows of them is its island. Left unstated, there is no home bar.
      for (final body in bodies) {
        expect(body.showCamera, isFalse);
        expect(body.showStatusBar, isFalse);
        expect(body.showGestureBar, isFalse);
      }
    });

    testComponents('the gesture bar flag and the screen brightness reach '
        'every body; the camera and the status never do — they are the '
        'island’s', (tester) async {
      tester.pumpComponent(
        Theme.defaults(
          child: const MockupFoldable(
            foldAngle: CoreMockupFold.halfOpen,
            showGestureBar: true,
            screenBrightness: CoreBrightness.dark,
            child: div([]),
          ),
        ),
      );
      await tester.pump();

      final bodies = _bodies();
      expect(bodies, hasLength(4));
      for (final body in bodies) {
        // Stated true on the device, and still not the bodies' to draw.
        expect(body.showCamera, isFalse);
        expect(body.showStatusBar, isFalse);
        expect(body.showGestureBar, isTrue);
        expect(body.screenBrightness, CoreBrightness.dark);
      }
    });

    testComponents('each body is handed the nested style the resolver '
        'settled, as it is', (tester) async {
      const rail = CoreColor(0xFFAA5500);
      await _pump(
        tester,
        CoreMockupFold.halfOpen,
        child: const div([]),
        style: const CoreMockupFoldableStyle(
          coverDeviceStyle: CoreMockupDeviceStyle(railColor: rail),
        ),
      );
      final bodies = _bodies();
      final cover = bodies.singleWhere(
        (face) => face.device == CoreMockupFoldableLayout.coverDevice,
      );
      final inner = bodies.firstWhere(
        (face) => face.device == CoreMockupFoldableLayout.innerDevice,
      );

      expect(cover.mockupDeviceStyle!.railColor, rail);
      expect(inner.mockupDeviceStyle!.railColor, isNot(rail));
      // The values the two bodies must agree on come pinned.
      expect(cover.mockupDeviceStyle!.borderRadius, isNotNull);
      expect(inner.mockupDeviceStyle!.borderRadius, isNotNull);
    });
  });

  group('MockupFoldable — a change of angle', () {
    testComponents('without frames the device is drawn at the new angle at '
        'once', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const div([]));
      expect(_has(_device().cover, 'hidden'), isTrue);
      expect(_has(_device().live, 'invisible'), isFalse);

      await _fold(tester, CoreMockupFold.closed);
      final shut = _device();
      expect(_has(shut.cover, 'hidden'), isFalse);
      expect(_has(shut.live, 'invisible'), isTrue);
      expect(_has(shut.leftHalf, 'hidden'), isTrue);

      // The same picture a device built shut is.
      final drawn = _transform(shut.cover);
      await _pump(tester, CoreMockupFold.closed, child: const div([]));
      expect(drawn, _transform(_device().cover));
    });

    testComponents('a step that crosses no rule rewrites the styles around '
        'the bodies and leaves the bodies as they are', (tester) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const _Counter());
      final before = _bodies();
      final placed = _transform(_device().leftHalf);
      final builds = _counters.length;

      await _fold(tester, 120);
      final after = _bodies();

      expect(_transform(_device().leftHalf), isNot(placed));
      expect(after, hasLength(before.length));
      for (var i = 0; i < before.length; i++) {
        expect(identical(after[i], before[i]), isTrue, reason: 'body $i');
      }
      // Nothing under them was built again.
      expect(_counters, hasLength(builds));
    });

    testComponents('a step that moves the content to the other screen '
        'rebuilds the bodies around it', (tester) async {
      await _pump(tester, 40, child: const _Counter());
      final before = _bodies();

      await _fold(tester, 20);
      final after = _bodies();

      expect(identical(after.first, before.first), isFalse);
      expect(_isUnder(_original, _device().cover), isTrue);
    });

    testComponents('the device keeps its parts, in their order, at every '
        'angle', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const div([]));

      for (final angle in [180.0, 144.0, 90.0, 60.0, 30.0, 0.0, 180.0]) {
        await _fold(tester, angle);
        final device = _device();
        for (final part in [
          device.live,
          device.rightHalf,
          device.rightEdge,
          device.leftHalf,
          device.leftEdge,
          device.cover,
        ]) {
          expect(part.component.tag, 'div', reason: '$angle°');
          expect(_has(part, 'absolute'), isTrue, reason: '$angle°');
        }
        // A half is a turned box around its one cut, whatever the cut
        // holds.
        for (final half in [device.rightHalf, device.leftHalf]) {
          expect(_cutOf(half).component.tag, 'div', reason: '$angle°');
        }
        // An edge is a strip around its one fill; the cover always holds
        // its body, the dark of its screen and its shade.
        for (final edge in [device.rightEdge, device.leftEdge]) {
          expect(_has(edge, 'overflow-hidden'), isTrue, reason: '$angle°');
          final fill = _domChildren(edge).single;
          expect(fill.component.tag, 'div', reason: '$angle°');
          expect(_has(fill, 'h-full'), isTrue, reason: '$angle°');
          expect(_domChildren(fill), isEmpty, reason: '$angle°');
        }
        expect(_domChildren(device.cover), hasLength(3));
        expect(_domChildren(device.live), hasLength(1));
      }
    });
  });

  group('MockupFoldable — the status island', () {
    testComponents('every body that is drawn carries its screen’s island: '
        'the open body, both copies and the cover', (tester) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const _Counter());
      final device = _device();

      for (final part in [device.live, device.rightHalf, device.leftHalf]) {
        final island = _islandsUnder(part).single;
        final parts = _domChildren(island);

        // The inner screen's: the clock and the status indicator.
        expect(island.component.attributes, {'aria-hidden': 'true'});
        expect(parts.map((part) => part.component.tag), ['span', 'div']);
        expect(find.text('9:41'), findsNComponents(4));
        final drawings = _domChildren(parts.last);
        expect(drawings.map((d) => d.component.tag), ['svg', 'svg']);
        for (final drawing in drawings) {
          expect(drawing.component.attributes!['aria-hidden'], 'true');
          expect(drawing.component.attributes!['viewBox'], isNotNull);
          final path = _domChildren(drawing).single;
          expect(path.component.tag, 'path');
          expect(path.component.attributes!['fill'], 'currentColor');
          expect(path.component.attributes!['d'], isNotEmpty);
        }
      }
      // The cover's starts with its camera.
      final onCover = _domChildren(_islandsUnder(device.cover).single);
      expect(onCover.map((part) => part.component.tag), ['div', 'span', 'div']);
      expect(
        onCover.first.component.styles!.properties['border-radius'],
        isNotNull,
      );
    });

    testComponents('open flat no copy is drawn, so there are two: the open '
        'body’s and the cover’s', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Counter());
      final device = _device();

      expect(_islandsUnder(device.live), hasLength(1));
      expect(_islandsUnder(device.rightHalf), isEmpty);
      expect(_islandsUnder(device.leftHalf), isEmpty);
      expect(_islandsUnder(device.cover), hasLength(1));
    });

    testComponents('the content sits in the room the island leaves it: a '
        'box as tall as the screen that stops short of the island’s column, '
        'with the island beside the content’s holder', (tester) async {
      await _pump(tester, CoreMockupFold.flat, child: const _Counter());
      final [holder, room, ...] = _boxesAround(_original);

      // The holder draws no box; the room is what lays the content out.
      expect(_has(holder, 'contents'), isTrue);
      expect(_has(room, 'h-full'), isTrue);
      final styles = room.component.styles!.properties;
      expect(styles['box-sizing'], 'border-box');
      expect(
        double.parse(styles['padding-right']!.replaceFirst('rem', '')) * 16,
        closeTo(
          CoreMockupFoldableStyle.defaultIslandWidth *
              CoreMockupFoldableStyle.defaultSystemScale,
          1e-9,
        ),
      );
      // The island is over the room's content, after it: the holder first.
      final inRoom = _domChildren(room);
      expect(inRoom, hasLength(2));
      expect(identical(inRoom.first, holder), isTrue);
      expect(_islandsUnder(room).single, inRoom.last);
    });

    testComponents('a screen that gives the content up keeps its island', (
      tester,
    ) async {
      await _pump(tester, CoreMockupFold.closed, child: const _Counter());
      final device = _device();

      expect(_isUnder(_original, device.cover), isTrue);
      // The open body holds nothing now, and still shows its status.
      final island = _islandsUnder(device.live).single;
      final room = _boxesAround(island).first;
      final holder = _domChildren(room).first;
      expect(_has(holder, 'contents'), isTrue);
      expect(_domChildren(holder), isEmpty);
      expect(_domChildren(island), hasLength(2));
      // And back: the island was not in the content's way either time.
      await _fold(tester, CoreMockupFold.flat);
      expect(_isUnder(_original, _device().live), isTrue);
      expect(_islandsUnder(_device().live), hasLength(1));
    });

    testComponents('hiding the status takes the island off the inner screen '
        'and leaves the cover its camera; hiding the camera too leaves no '
        'island — and the content keeps what it holds through both', (
      tester,
    ) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const _Counter());
      final original = _counters.first..increment();
      await tester.pump();

      _HostState.current.show(status: false);
      await tester.pump();
      var device = _device();
      for (final part in [device.live, device.rightHalf, device.leftHalf]) {
        expect(_islandsUnder(part), isEmpty);
      }
      expect(find.text('9:41'), findsNothing);
      expect(
        _domChildren(_islandsUnder(device.cover).single).map(
          (part) => part.component.tag,
        ),
        ['div'],
      );
      // The inner screen's room is the whole screen again.
      expect(_boxesAround(_original)[1].component.styles, isNull);
      expect(original.mounted, isTrue);
      expect(original.count, 1);

      _HostState.current.show(camera: false);
      await tester.pump();
      device = _device();
      expect(_islandsUnder(device.root), isEmpty);
      expect(original.mounted, isTrue);
      expect(original.count, 1);

      // Shown again, they come back where they were.
      _HostState.current.show(camera: true, status: true);
      await tester.pump();
      expect(_islandsUnder(_device().root), hasLength(4));
      expect(original.count, 1);
    });

    testComponents('a change of the island’s style redraws the bodies; a '
        'step of the angle alone does not', (tester) async {
      await _pump(tester, CoreMockupFold.halfOpen, child: const _Counter());
      double padding() => double.parse(
        _boxesAround(_original)[1]
            .component
            .styles!
            .properties['padding-right']!
            .replaceFirst('rem', ''),
      );
      final before = _bodies();
      final narrow = padding();

      await _fold(tester, 120);
      expect(identical(_bodies().first, before.first), isTrue);
      expect(padding(), narrow);

      _HostState.current.restyle(
        const CoreMockupFoldableStyle(islandWidth: 144),
      );
      await tester.pump();
      // Had the bodies been kept, the room would still be the old width.
      expect(identical(_bodies().first, before.first), isFalse);
      expect(padding(), closeTo(narrow * 144 / 96, 1e-9));
      // The content was moved into the new bodies, not built anew.
      expect(_counters.first.mounted, isTrue);
    });
  });

  group('MockupFoldable — the chain', () {
    test('withStyle merges a patch, and a later patch wins', () {
      const device = MockupFoldable(child: div([]));
      final styled = device
          .withStyle(const CoreMockupFoldableStyle(thickness: 20))
          .withStyle(
            const CoreMockupFoldableStyle(thickness: 24, perspective: 3),
          );

      expect(styled.mockupFoldableStyle!.thickness, 24);
      expect(styled.mockupFoldableStyle!.perspective, 3);
      expect(device.mockupFoldableStyle, isNull);
    });

    test('copyWith replaces what it is given and keeps the rest', () {
      const child = div([]);
      const device = MockupFoldable(
        foldAngle: 60,
        width: 320,
        showCamera: false,
        id: 'fold',
        classes: 'mt-4',
        attributes: {'data-test': 'yes'},
        child: child,
      );
      final copy = device.copyWith(foldAngle: 144, classes: 'mx-auto');

      expect(copy.foldAngle, 144);
      expect(copy.width, 320);
      expect(copy.showCamera, isFalse);
      expect(copy.showStatus, device.showStatus);
      expect(copy.showGestureBar, device.showGestureBar);
      expect(copy.id, 'fold');
      // Added to the classes it had, not put in their place.
      expect(copy.classes!.split(' ').toSet(), {'mt-4', 'mx-auto'});
      expect(copy.userAttributes, {'data-test': 'yes'});
      expect(identical(copy.child, child), isTrue);
    });

    test('an angle left unstated is open flat', () {
      expect(
        const MockupFoldable(child: div([])).foldAngle,
        CoreMockupFold.flat,
      );
    });

    test('left unstated the camera and the status show and the home bar '
        'does not — the contract’s defaults — and copyWith replaces each', () {
      const device = MockupFoldable(child: div([]));

      expect(device.showCamera, CoreMockupFoldableContract.defaultShowCamera);
      expect(device.showStatus, CoreMockupFoldableContract.defaultShowStatus);
      expect(
        device.showGestureBar,
        CoreMockupFoldableContract.defaultShowGestureBar,
      );
      expect(device.showCamera, isTrue);
      expect(device.showStatus, isTrue);
      expect(device.showGestureBar, isFalse);

      final copy = device.copyWith(
        showCamera: false,
        showStatus: false,
        showGestureBar: true,
      );
      expect(copy.showCamera, isFalse);
      expect(copy.showStatus, isFalse);
      expect(copy.showGestureBar, isTrue);
    });
  });
}
