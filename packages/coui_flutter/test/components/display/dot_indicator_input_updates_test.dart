import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

const ValueKey<String> _kSubjectKey = ValueKey('dot-subject');
const _kOldActive = 0xff123456;
const _kNewActive = 0xffab2345;
const _kNewInactive = 0xff23ab45;
const _kNewHoverBorder = 0xff8844cc;

class _DotHost extends StatefulWidget {
  const _DotHost({
    super.key,
    this.initialStyle,
    this.initialDirection = CoreAxis.horizontal,
    this.maxMain = 700,
  });

  final CoreDotIndicatorStyle? initialStyle;
  final CoreAxis initialDirection;
  final double maxMain;

  @override
  State<_DotHost> createState() => _DotHostState();
}

class _DotHostState extends State<_DotHost> {
  CoreDotIndicatorStyle? style;
  CoreDotIndicatorSize size = CoreDotIndicatorSize.md;
  CoreAxis direction = CoreAxis.horizontal;
  bool interactive = true;
  final events = <int>[];

  @override
  void initState() {
    super.initState();
    style = widget.initialStyle;
    direction = widget.initialDirection;
  }

  void update({
    CoreDotIndicatorStyle? style,
    CoreDotIndicatorSize? size,
    CoreAxis? direction,
    bool? interactive,
  }) {
    setState(() {
      if (style != null) this.style = style;
      if (size != null) this.size = size;
      if (direction != null) this.direction = direction;
      if (interactive != null) this.interactive = interactive;
    });
  }

  void handleChanged(int value) => events.add(value);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: direction == CoreAxis.horizontal
        ? BoxConstraints(maxWidth: widget.maxMain, maxHeight: 500)
        : BoxConstraints(maxWidth: 500, maxHeight: widget.maxMain),
    child: DotIndicator(
      key: _kSubjectKey,
      length: 5,
      index: 2,
      onChanged: interactive ? handleChanged : null,
      size: size,
      direction: direction,
      dotIndicatorStyle: style,
    ),
  );
}

Future<GlobalKey<_DotHostState>> _pumpHost(
  WidgetTester tester, {
  CoreDotIndicatorStyle? style,
  CoreAxis direction = CoreAxis.horizontal,
  double maxMain = 700,
}) async {
  final key = GlobalKey<_DotHostState>();
  // Only the host below this stable theme is updated by each test.
  await tester.pumpWidget(
    widgets.WidgetsApp(
      color: const Color(0xff000000),
      builder: (context, _) => Theme(
        data: ThemeData.fromCore(CoreThemePresets.light),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: _DotHost(
              key: key,
              initialStyle: style,
              initialDirection: direction,
              maxMain: maxMain,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Finder get _subject => find.byKey(_kSubjectKey);
Finder get _markers =>
    find.descendant(of: _subject, matching: find.byType(AnimatedContainer));
Finder get _inactive => find.descendant(
  of: _subject,
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_InactiveDotItem',
  ),
);

BoxDecoration _paint(WidgetTester tester, int index) =>
    tester
            .renderObject<RenderDecoratedBox>(
              find.descendant(
                of: _markers.at(index),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

double _hoverScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.ancestor(of: _markers.first, matching: find.byType(AnimatedScale)),
    )
    .scale;

List<Object> _animationStates(WidgetTester tester) => [
  for (final element in _markers.evaluate())
    tester.state(find.byElementPredicate((candidate) => candidate == element)),
];

void _expectSameStates(WidgetTester tester, List<Object> previous) {
  final current = _animationStates(tester);
  expect(current, hasLength(previous.length));
  for (var index = 0; index < previous.length; index++) {
    expect(identical(current[index], previous[index]), isTrue);
  }
}

RenderFlex _flex(WidgetTester tester) => tester.renderObject<RenderFlex>(
  find.descendant(of: _subject, matching: find.byType(Flex)),
);

void main() {
  testWidgets('explicit style updates paint without replacing marker state', (
    tester,
  ) async {
    final host = await _pumpHost(
      tester,
      style: const CoreDotIndicatorStyle(
        dotSize: 8,
        activeLength: 16,
        activeColor: CoreColor(_kOldActive),
        inactiveColor: CoreColor(0xff345678),
        inactiveBorderWidth: 1,
        borderRadius: CoreBorderRadius.all(2),
      ),
    );
    final rootElement = tester.element(_subject);
    final inactiveState = tester.state(_inactive.first);
    final animationStates = _animationStates(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 550));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_markers.first));
    await tester.pumpAndSettle();
    expect(_hoverScale(tester), 1.1);

    host.currentState!.update(
      style: const CoreDotIndicatorStyle(
        dotSize: 12,
        activeLength: 24,
        activeColor: CoreColor(_kNewActive),
        inactiveColor: CoreColor(_kNewInactive),
        hoverBorderColor: CoreColor(_kNewHoverBorder),
        inactiveBorderWidth: 2,
        borderRadius: CoreBorderRadius.all(6),
      ),
    );
    await tester.pumpAndSettle();

    expect(_paint(tester, 2).color, const Color(_kNewActive));
    expect(_paint(tester, 0).color, const Color(_kNewInactive));
    expect(
      (_paint(tester, 0).border! as Border).top.color,
      const Color(_kNewHoverBorder),
    );
    expect((_paint(tester, 0).border! as Border).top.width, 2);
    expect(_paint(tester, 0).borderRadius, BorderRadius.circular(6));
    expect(tester.getSize(_markers.at(2)), const Size(24, 12));
    expect(tester.getSize(_markers.first), const Size(12, 12));
    expect(_hoverScale(tester), 1.1);
    expect(identical(rootElement, tester.element(_subject)), isTrue);
    expect(identical(inactiveState, tester.state(_inactive.first)), isTrue);
    _expectSameStates(tester, animationStates);
  });

  testWidgets('semantic size updates the existing private markers', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    final animationStates = _animationStates(tester);
    host.currentState!.update(size: CoreDotIndicatorSize.sm);
    await tester.pumpAndSettle();
    for (final marker in _markers.evaluate()) {
      expect((marker.renderObject! as RenderBox).size, const Size(6, 6));
    }
    _expectSameStates(tester, animationStates);
  });

  testWidgets('direction updates the existing elongated active marker', (
    tester,
  ) async {
    final host = await _pumpHost(
      tester,
      style: const CoreDotIndicatorStyle(dotSize: 8, activeLength: 20),
    );
    final animationStates = _animationStates(tester);
    host.currentState!.update(direction: CoreAxis.vertical);
    await tester.pumpAndSettle();
    expect(_flex(tester).direction, Axis.vertical);
    expect(tester.getSize(_markers.at(2)), const Size(8, 20));
    _expectSameStates(tester, animationStates);
  });

  testWidgets('callback transitions retain the existing branch remount', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    final publicState = tester.state(_subject);
    final initialInactive = tester.state(_inactive.first);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 550));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_markers.first));
    await tester.pumpAndSettle();
    expect(_hoverScale(tester), 1.1);

    host.currentState!.update(interactive: false);
    await tester.pumpAndSettle();
    final passiveInactive = tester.state(_inactive.first);
    expect(identical(passiveInactive, initialInactive), isFalse);
    expect(_hoverScale(tester), 1);
    await mouse.moveTo(const Offset(700, 550));
    host.currentState!.update(interactive: true);
    await tester.pumpAndSettle();
    expect(identical(passiveInactive, tester.state(_inactive.first)), isFalse);
    expect(_hoverScale(tester), 1);
    await mouse.moveTo(tester.getCenter(_markers.first));
    await tester.pumpAndSettle();
    expect(_hoverScale(tester), 1.1);
    await tester.tapAt(tester.getCenter(_markers.first));
    expect(host.currentState!.events, [0]);
    expect(identical(publicState, tester.state(_subject)), isTrue);
  });

  for (final direction in CoreAxis.values) {
    testWidgets('$direction public style motion keeps current-size fit', (
      tester,
    ) async {
      for (final ramp in [
        [12.0, 8.0],
        [8.0, 12.0],
      ]) {
        final host = await _pumpHost(
          tester,
          direction: direction,
          maxMain: 88,
          style: CoreDotIndicatorStyle(dotSize: ramp[0]),
        );
        final states = _animationStates(tester);
        host.currentState!.update(
          style: CoreDotIndicatorStyle(dotSize: ramp[1]),
        );
        await tester.pump();
        if (ramp[0] == 8) {
          expect(
            direction == CoreAxis.horizontal
                ? _flex(tester).constraints.maxWidth
                : _flex(tester).constraints.maxHeight,
            double.infinity,
          );
        }
        // These are cumulative 16ms and 50ms samples, not two 50ms pumps.
        for (final delta in [16, 34]) {
          await tester.pump(Duration(milliseconds: delta));
          final current = tester.getSize(_markers.first);
          final cross = direction == CoreAxis.horizontal
              ? current.height
              : current.width;
          expect(cross, inExclusiveRange(8, 12));
          expect(
            direction == CoreAxis.horizontal
                ? _flex(tester).constraints.maxWidth
                : _flex(tester).constraints.maxHeight,
            88,
          );
          _expectSameStates(tester, states);
        }
        await tester.pumpAndSettle();
        if (ramp[1] == 8) {
          for (final marker in _markers.evaluate()) {
            expect((marker.renderObject! as RenderBox).size, const Size(8, 8));
          }
          expect(
            direction == CoreAxis.horizontal
                ? _flex(tester).constraints.maxWidth
                : _flex(tester).constraints.maxHeight,
            double.infinity,
          );
        }
        _expectSameStates(tester, states);
      }
    });
  }
}
