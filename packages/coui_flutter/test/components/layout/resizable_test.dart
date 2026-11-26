import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestSize = 200.0;
const _kTestFlex = 0.5;
const _kDragOffset = 40.0;
const _kWidthEpsilon = 0.5;
const _kKeyboardStep = CoreResizableContract.defaultKeyboardStepFraction;

/// The left pane's `initialSize: 0.3` as the percentage its divider
/// announces.
const _kLeftPanePercent = 30;

/// Ratio → percent, mirroring the component's own conversion so an expected
/// percentage is derived the way the announced one is rather than
/// transcribed.
const _kPercentScale = 100;

/// Ratios are compared well below one announced percent, so rounding never
/// decides whether the layout and the announcement agree.
const _kRatioEpsilon = 0.002;

/// A declared ratio that sits below the floor its own pane declares — the
/// issue's reproduction, and the shape that froze the keyboard.
const _kViolatingRatio = 0.3;

/// The floor [_kViolatingRatio] violates. Also serves as a floor that cannot
/// be satisfied alongside [_kViolatedCeiling] as a second pane's floor,
/// since the two together ask for 110% of the container.
const _kViolatingFloor = 0.5;

/// A ceiling a declared ratio of `0.9` overshoots — the mirror of
/// [_kViolatingFloor], exercising the opposite bound.
const _kViolatedCeiling = 0.6;

/// The divider's own `Semantics` — the only slider in a single-divider
/// subtree. Reading the properties off the widget rather than the semantics
/// tree keeps `minValue` / `maxValue` available as the raw strings the web
/// engine forwards to `aria-valuemin` / `aria-valuemax`.
List<SemanticsProperties> _dividerProperties(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((w) => w.properties)
    .where((p) => p.slider ?? false)
    .toList();

/// Asserts the announced position lies inside the announced bounds.
///
/// Stated as "`value` is one of the sentences this divider could speak for a
/// position in `[minValue, maxValue]`" rather than by re-deriving the
/// position: the position is only exposed as a sentence on this platform,
/// and an inverted range makes that set empty, which is the failure the Web
/// twin shows as `aria-valuenow` outside `[aria-valuemin, aria-valuemax]`.
void _expectValueWithinBounds(SemanticsProperties props) {
  final min = int.parse(props.minValue!);
  final max = int.parse(props.maxValue!);
  expect(min, lessThanOrEqualTo(max), reason: 'announced range is inverted');
  expect(
    [
      for (var percent = min; percent <= max; percent++)
        DefaultCoUILocalizations.instance.resizableDividerPositionLabel(
          percent,
        ),
    ],
    contains(props.value),
    reason: 'announced position is outside the announced range',
  );
}

/// The fraction of the container each pane is actually drawn at.
///
/// This is the other number in the pair the issue is about: an announcement
/// is only true if it names the fraction the panes were laid out at, so
/// every assertion below reads both out of the same pumped frame.
List<double> _renderedRatios(WidgetTester tester) {
  final panes = find.byType(material.Expanded);
  final widths = [
    for (var i = 0; i < panes.evaluate().length; i++)
      tester.getSize(panes.at(i)).width,
  ];
  final total = widths.fold<double>(0, (sum, width) => sum + width);
  return [for (final width in widths) width / total];
}

material.Widget _resizable({
  required List<CoreResizablePaneData<material.Widget>> panes,
  void Function(List<double> sizes)? onResize,
}) => _buildApp(
  material.SizedBox(
    width: _kTestSize,
    height: _kTestSize,
    child: Resizable(panes: panes, onResize: onResize),
  ),
);

CoreResizablePaneData<material.Widget> _pane({
  required double initialSize,
  double? minSize,
  double? maxSize,
}) => CoreResizablePaneData<material.Widget>(
  content: const material.SizedBox.expand(),
  initialSize: initialSize,
  minSize: minSize,
  maxSize: maxSize,
);

void main() {
  group('Resizable', () {
    testWidgets('renders both pane contents', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: [
                CoreResizablePaneData(content: material.Text('Left Pane')),
                CoreResizablePaneData(content: material.Text('Right Pane')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Left Pane'), findsOneWidget);
      expect(find.text('Right Pane'), findsOneWidget);
    });

    testWidgets('hides drag dots by default', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: [
                CoreResizablePaneData(content: material.SizedBox()),
                CoreResizablePaneData(content: material.SizedBox()),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows grab handle when showDragHandle is true', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: [
                CoreResizablePaneData(content: material.SizedBox()),
                CoreResizablePaneData(content: material.SizedBox()),
              ],
              showDragHandle: true,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('panes fill the container flush (no divider gutter)', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: [
                CoreResizablePaneData(
                  content: material.Text('Left Pane'),
                ),
                CoreResizablePaneData(
                  content: material.Text('Right Pane'),
                ),
              ],
              showDragHandle: true,
            ),
          ),
        ),
      );

      // Equal panes with no reserved divider gutter — each pane gets
      // exactly half the container width (the thin line + handle are
      // overlays that do not consume layout width).
      final leftWidth = tester.getSize(find.text('Left Pane')).width;
      final rightWidth = tester.getSize(find.text('Right Pane')).width;
      expect(leftWidth, moreOrLessEquals(rightWidth, epsilon: _kWidthEpsilon));
    });

    testWidgets('dragging the floating grab handle resizes the panes', (
      tester,
    ) async {
      final emitted = <List<double>>[];
      final _ = await tester.pumpWidget(
        _buildApp(
          material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: const [
                CoreResizablePaneData(
                  content: material.SizedBox(),
                  initialSize: _kTestFlex,
                ),
                CoreResizablePaneData(
                  content: material.SizedBox(),
                  initialSize: _kTestFlex,
                ),
              ],
              onResize: emitted.add,
              showDragHandle: true,
            ),
          ),
        ),
      );

      // The grab handle floats over the seam — dragging it right grows the
      // left pane.
      final _ = await tester.drag(
        find.byType(Icon),
        const material.Offset(_kDragOffset, 0),
      );
      await tester.pump();

      expect(emitted, isNotEmpty);
      expect(emitted.last.first, greaterThan(_kTestFlex));
    });

    testWidgets('dragging the thin divider line resizes the panes', (
      tester,
    ) async {
      final emitted = <List<double>>[];
      final _ = await tester.pumpWidget(
        _buildApp(
          material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: const [
                CoreResizablePaneData(
                  content: material.SizedBox(),
                  initialSize: _kTestFlex,
                ),
                CoreResizablePaneData(
                  content: material.SizedBox(),
                  initialSize: _kTestFlex,
                ),
              ],
              onResize: emitted.add,
            ),
          ),
        ),
      );

      // No handle on pointer platforms — the thin line (the only
      // AnimatedContainer) carries the drag via its enlarged hit area.
      final _ = await tester.drag(
        find.byType(AnimatedContainer),
        const material.Offset(_kDragOffset, 0),
      );
      await tester.pump();

      expect(emitted, isNotEmpty);
      expect(emitted.last.first, greaterThan(_kTestFlex));
    });

    testWidgets(
      'flipping direction preserves descendant State '
      '(regression: Row/Column swap destroyed panes)',
      (tester) async {
        final tracker = _MountTracker();

        Future<void> pumpWithDirection(CoreResizableDirection direction) {
          return tester.pumpWidget(
            _buildApp(
              material.SizedBox(
                width: _kTestSize,
                height: _kTestSize,
                child: Resizable(
                  panes: [
                    CoreResizablePaneData(content: _Probe(tracker: tracker)),
                    const CoreResizablePaneData(
                      content: material.SizedBox(),
                    ),
                  ],
                  direction: direction,
                ),
              ),
            ),
          );
        }

        void expectProbeUntouched() {
          expect(tracker.mountCount, 1);
          expect(tracker.disposeCount, 0);
        }

        await pumpWithDirection(.vertical);
        expectProbeUntouched();

        // Flipping direction used to branch between `Row` and `Column` —
        // distinct `Flex` subclasses — so `Widget.canUpdate` failed and the
        // whole pane subtree (including this probe) was unmounted and
        // remounted from scratch. A single `Flex` with a variable
        // `direction` keeps the same element, so the probe's State must
        // survive untouched.
        await pumpWithDirection(.horizontal);
        expectProbeUntouched();
      },
    );

    group('keyboard resize (WCAG 2.1.1, #3496)', () {
      testWidgets(
        'ArrowRight resizes the left pane by one keyboard step after '
        'Tab focus',
        (tester) async {
          final emitted = <List<double>>[];
          final _ = await tester.pumpWidget(
            _buildApp(
              material.SizedBox(
                width: _kTestSize,
                height: _kTestSize,
                child: Resizable(
                  panes: const [
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: _kTestFlex,
                    ),
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: _kTestFlex,
                    ),
                  ],
                  onResize: emitted.add,
                ),
              ),
            ),
          );

          // Nothing else in this tree competes for focus, so a single Tab
          // reaches the divider — exactly how a keyboard-only user (no
          // mouse/touch) would arrive at it.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          expect(emitted, isEmpty);

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();

          // This is the actual size change, not just presence of a
          // focusable node — a revert to a tabindex-only fix leaves
          // `emitted` empty and fails here.
          expect(emitted, isNotEmpty);
          expect(
            emitted.last.first,
            moreOrLessEquals(_kTestFlex + _kKeyboardStep),
          );
          expect(
            emitted.last.last,
            moreOrLessEquals(_kTestFlex - _kKeyboardStep),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pump();

          expect(emitted.last.first, moreOrLessEquals(_kTestFlex));
        },
      );

      testWidgets(
        'ArrowDown resizes the top pane for a vertical split; the '
        'horizontal-split keys are ignored',
        (tester) async {
          final emitted = <List<double>>[];
          final _ = await tester.pumpWidget(
            _buildApp(
              material.SizedBox(
                width: _kTestSize,
                height: _kTestSize,
                child: Resizable(
                  direction: .vertical,
                  panes: const [
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: _kTestFlex,
                    ),
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: _kTestFlex,
                    ),
                  ],
                  onResize: emitted.add,
                ),
              ),
            ),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          // ARIA APG "window splitter": Left/Right belong to a
          // horizontal split's vertical divider line, not this
          // vertical split's horizontal one.
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();
          expect(emitted, isEmpty);

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();

          expect(emitted, isNotEmpty);
          expect(
            emitted.last.first,
            moreOrLessEquals(_kTestFlex + _kKeyboardStep),
          );
        },
      );

      testWidgets(
        'keyboard resize respects minSize/maxSize the same way drag does',
        (tester) async {
          final emitted = <List<double>>[];
          final _ = await tester.pumpWidget(
            _buildApp(
              material.SizedBox(
                width: _kTestSize,
                height: _kTestSize,
                child: Resizable(
                  panes: const [
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: _kTestFlex,
                      maxSize: _kTestFlex,
                    ),
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: _kTestFlex,
                    ),
                  ],
                  onResize: emitted.add,
                ),
              ),
            ),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();

          // Left pane is already at its maxSize — the press is clamped
          // away entirely, same as a drag past the limit.
          expect(emitted, isEmpty);
        },
      );

      testWidgets(
        'the divider Semantics announces the current position as a '
        'percent value',
        (tester) async {
          final _ = await tester.pumpWidget(
            _buildApp(
              const material.SizedBox(
                width: _kTestSize,
                height: _kTestSize,
                child: Resizable(
                  panes: [
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: 0.3,
                    ),
                    CoreResizablePaneData(
                      content: material.SizedBox(),
                      initialSize: 0.7,
                    ),
                  ],
                ),
              ),
            ),
          );

          final data = tester
              .getSemantics(find.byType(AnimatedContainer))
              .getSemanticsData();

          // "조작은 되는데 지금 얼마인지 모른다" is only half fixed — this
          // is the other half (#3496 point 3): the value a screen
          // reader would actually announce, read straight off live
          // `_sizes` state, not a hardcoded string.
          expect(data.hasFlag(SemanticsFlag.isSlider), isTrue);
          // The number is anchored to a literal, independently of the
          // formatter: routing the expectation through the same
          // localizations the widget reads would make this test agree
          // with any ratio the widget announced, which is the one thing
          // it exists to catch.
          expect(data.value, contains('$_kLeftPanePercent'));
          // The wording is asserted through the locale's own formatter,
          // so a copy change reads as a copy change here rather than as
          // a broken ratio. The sentence is pinned in
          // `l10n_wiring_test.dart`.
          expect(
            data.value,
            DefaultCoUILocalizations.instance.resizableDividerPositionLabel(
              _kLeftPanePercent,
            ),
          );
        },
      );
    });

    // Every case below gets its own `testWidgets`. Pumping a second pane
    // list inside one test reuses the same `State`, so `initState` does not
    // run again and the second case silently reads the first one's sizes —
    // which is a property of the component worth testing (it is, at the end
    // of this group), not a way to write the others.
    group('initialSize normalisation (#4050)', () {
      testWidgets(
        'a ratio below its own minSize is announced and drawn at the same '
        'position',
        (tester) async {
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(
                  initialSize: _kViolatingRatio,
                  minSize: _kViolatingFloor,
                ),
                _pane(initialSize: 0.7),
              ],
            ),
          );

          final rendered = _renderedRatios(tester);
          final props = _dividerProperties(tester).single;

          // The pair the issue is about, read out of one frame: the number
          // spoken and the number drawn. Announcing a clamped 50% over a
          // layout still drawn at 30% satisfied neither half.
          expect(
            props.value,
            DefaultCoUILocalizations.instance.resizableDividerPositionLabel(
              (rendered.first * _kPercentScale).round(),
            ),
          );
          expect(
            rendered.first,
            moreOrLessEquals(0.5, epsilon: _kRatioEpsilon),
          );
        },
      );

      testWidgets('a ratio above its own maxSize gets the same treatment', (
        tester,
      ) async {
        final _ = await tester.pumpWidget(
          _resizable(
            panes: [
              _pane(initialSize: 0.9, maxSize: _kViolatedCeiling),
              _pane(initialSize: 0.1),
            ],
          ),
        );

        final rendered = _renderedRatios(tester);
        final props = _dividerProperties(tester).single;

        expect(
          props.value,
          DefaultCoUILocalizations.instance.resizableDividerPositionLabel(
            (rendered.first * _kPercentScale).round(),
          ),
        );
        expect(
          rendered.first,
          moreOrLessEquals(_kViolatedCeiling, epsilon: _kRatioEpsilon),
        );
      });

      testWidgets(
        'ratios that do not add up to the container are announced at the '
        'fraction they are drawn at',
        (tester) async {
          // No bound is violated here — the ratios simply miss the whole,
          // and the layout normalises by their total while the announcement
          // read them as fractions of the container. A test that only picks
          // sums of 1 never sees this.
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(initialSize: _kViolatingRatio),
                _pane(initialSize: _kViolatingRatio),
              ],
            ),
          );

          final rendered = _renderedRatios(tester);
          expect(
            rendered.first,
            moreOrLessEquals(0.5, epsilon: _kRatioEpsilon),
          );
          expect(
            _dividerProperties(tester).single.value,
            DefaultCoUILocalizations.instance.resizableDividerPositionLabel(
              (rendered.first * _kPercentScale).round(),
            ),
          );
        },
      );

      testWidgets(
        'the announced position sits inside the announced bounds',
        (tester) async {
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(
                  initialSize: _kViolatingRatio,
                  minSize: _kViolatingFloor,
                ),
                _pane(initialSize: 0.7),
              ],
            ),
          );

          // `minValue` / `maxValue` stay bare numbers because the web engine
          // forwards them into `aria-valuemin` / `aria-valuemax`, which is
          // exactly where the invalid range showed up.
          _expectValueWithinBounds(_dividerProperties(tester).single);
        },
      );

      testWidgets(
        'a middle pane whose minSize exceeds its share still renders '
        '(regression: num.clamp asserted on an inverted range)',
        (tester) async {
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(initialSize: 0.2),
                _pane(initialSize: 0.2, minSize: _kViolatingFloor),
                _pane(initialSize: 0.6),
              ],
            ),
          );

          // The widget used to throw `Invalid argument(s): 0.0` out of
          // `LayoutBuilder`, so nothing was drawn at all.
          expect(tester.takeException(), isNull);

          expect(_renderedRatios(tester), hasLength(3));
          for (final props in _dividerProperties(tester)) {
            _expectValueWithinBounds(props);
          }
        },
      );

      testWidgets(
        'two minSizes that cannot both fit still render a valid range',
        (tester) async {
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(initialSize: 0.5, minSize: _kViolatingFloor),
                _pane(initialSize: 0.5, minSize: _kViolatedCeiling),
              ],
            ),
          );

          // `min: .5` + `min: .6` asks for 110% of the container: no sizes
          // satisfy both, so reporting the floors unchanged left
          // `aria-valuemin` above `aria-valuemax` however the sizes moved.
          expect(tester.takeException(), isNull);
          _expectValueWithinBounds(_dividerProperties(tester).single);
        },
      );

      testWidgets(
        'a divider whose ratio violated its minSize still moves on '
        'ArrowRight (WCAG 2.1.1)',
        (tester) async {
          final emitted = <List<double>>[];
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(
                  initialSize: _kViolatingRatio,
                  minSize: _kViolatingFloor,
                ),
                _pane(initialSize: 0.7),
              ],
              onResize: emitted.add,
            ),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();

          // Every press used to be rejected: the step is 1% and the gap back
          // into the legal range was 20%, so no number of presses ever
          // closed it. The divider was reachable by Tab and frozen forever.
          expect(emitted, isNotEmpty);
          expect(
            emitted.last.first,
            moreOrLessEquals(
              _kViolatingFloor + _kKeyboardStep,
              epsilon: _kRatioEpsilon,
            ),
          );
          expect(
            _renderedRatios(tester).first,
            moreOrLessEquals(
              _kViolatingFloor + _kKeyboardStep,
              epsilon: _kRatioEpsilon,
            ),
          );
        },
      );

      testWidgets(
        'a step that would overshoot the bound lands on it rather than '
        'being dropped',
        (tester) async {
          final emitted = <List<double>>[];
          const floor = 0.495;
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(initialSize: _kTestFlex, minSize: floor),
                _pane(initialSize: _kTestFlex),
              ],
              onResize: emitted.add,
            ),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pump();

          // The step is 1% and the remaining travel is 0.5%. Refusing any
          // move that leaves the range makes the last half-step
          // unreachable, so a divider can be dragged towards its limit and
          // never arrive at it.
          expect(emitted, isNotEmpty);
          expect(
            emitted.last.first,
            moreOrLessEquals(floor, epsilon: _kRatioEpsilon),
          );
        },
      );

      testWidgets('emitted sizes add up to the container', (tester) async {
        final emitted = <List<double>>[];
        final _ = await tester.pumpWidget(
          _resizable(
            panes: [
              _pane(initialSize: _kViolatingRatio, minSize: _kViolatingFloor),
              _pane(initialSize: 0.7),
            ],
            onResize: emitted.add,
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        // A per-pane clamp turns the invalid ARIA range green while leaving
        // the sizes summing to 1.2 — which is the announce-vs-render split
        // this issue is actually about. Consumers persist what they get
        // here, so it has to be the fraction of the container each pane
        // occupies.
        expect(
          emitted.last.fold<double>(0, (sum, size) => sum + size),
          moreOrLessEquals(1, epsilon: _kRatioEpsilon),
        );
      });

      testWidgets(
        'a pane list swapped at runtime is normalised against its own '
        'bounds',
        (tester) async {
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [_pane(initialSize: 0.5), _pane(initialSize: 0.5)],
            ),
          );

          // Sizes resolved once at mount go on satisfying the bounds of a
          // pane list that no longer exists — the same out-of-range
          // announcement, reintroduced one rebuild later.
          final _ = await tester.pumpWidget(
            _resizable(
              panes: [
                _pane(initialSize: 0.5, minSize: 0.8),
                _pane(initialSize: 0.5),
              ],
            ),
          );

          final rendered = _renderedRatios(tester);
          expect(
            rendered.first,
            moreOrLessEquals(0.8, epsilon: _kRatioEpsilon),
          );

          final props = _dividerProperties(tester).single;
          expect(
            props.value,
            DefaultCoUILocalizations.instance.resizableDividerPositionLabel(
              (rendered.first * _kPercentScale).round(),
            ),
          );
          _expectValueWithinBounds(props);
        },
      );

      testWidgets('a rebuild that changes only content keeps dragged sizes', (
        tester,
      ) async {
        material.Widget build(String label) => _buildApp(
          material.SizedBox(
            width: _kTestSize,
            height: _kTestSize,
            child: Resizable(
              panes: [
                CoreResizablePaneData<material.Widget>(
                  content: material.Text(label),
                  initialSize: _kTestFlex,
                ),
                const CoreResizablePaneData<material.Widget>(
                  content: material.SizedBox.expand(),
                  initialSize: _kTestFlex,
                ),
              ],
            ),
          ),
        );

        final _ = await tester.pumpWidget(build('before'));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        final afterKeyPress = _renderedRatios(tester).first;
        expect(afterKeyPress, greaterThan(_kTestFlex));

        // Re-resolving on every rebuild would throw away what the user just
        // did. Only a changed *geometry* is a new declaration.
        final _ = await tester.pumpWidget(build('after'));
        expect(
          _renderedRatios(tester).first,
          moreOrLessEquals(afterKeyPress, epsilon: _kRatioEpsilon),
        );
      });

      testWidgets('growing the pane list keeps every divider operable', (
        tester,
      ) async {
        final emitted = <List<double>>[];
        final _ = await tester.pumpWidget(
          _resizable(
            panes: [_pane(initialSize: 0.5), _pane(initialSize: 0.5)],
            onResize: emitted.add,
          ),
        );

        // The focus nodes are indexed by divider; a pane list that gains a
        // pane gains a divider, and indexing the old list for it throws.
        final _ = await tester.pumpWidget(
          _resizable(
            panes: [
              _pane(initialSize: 0.2),
              _pane(initialSize: 0.3),
              _pane(initialSize: 0.5),
            ],
            onResize: emitted.add,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(_dividerProperties(tester), hasLength(2));

        // Reach the second divider — the one that did not exist a frame ago.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(emitted, isNotEmpty);
        expect(emitted.last, hasLength(3));
      });
    });
  });
}

/// Counts mount/dispose calls of [_Probe] instances that share it, so tests
/// can detect element identity loss without relying on [GlobalKey] (which
/// would mask the bug by relocating the element across ancestor-type
/// changes regardless of the fix under test).
class _MountTracker {
  int mountCount = 0;
  int disposeCount = 0;
}

class _Probe extends material.StatefulWidget {
  const _Probe({required this.tracker});

  final _MountTracker tracker;

  @override
  material.State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends material.State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.tracker.mountCount++;
  }

  @override
  void dispose() {
    widget.tracker.disposeCount++;
    super.dispose();
  }

  @override
  material.Widget build(material.BuildContext context) =>
      const material.SizedBox();
}
