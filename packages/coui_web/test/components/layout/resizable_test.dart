import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// Keyboard-driven value changes (`_handleDividerKeyDown`) aren't covered
// here — `dart test` runs this suite on the VM, and `universal_web`'s
// `KeyboardEvent.key` getter throws `Unsupported operation` outside a real
// browser/JS environment (no `dart_test.yaml` chrome platform is
// configured in this package; `Slider`'s own `slider_test.dart` documents
// the same limitation for the same reason). What's testable on the VM —
// the structural wiring that makes the divider keyboard-*reachable* and
// the value it would announce — is covered below. The live keyboard-drag
// path is covered on the Flutter side, in
// `resizable_test.dart`'s "keyboard resize (WCAG 2.1.1, #3496)" group.

/// The left pane's `initialSize: 0.3` as the percentage its divider
/// announces.
const _kLeftPanePercent = 30;

/// Ratio → percent, mirroring the component's own conversion.
const _kPercentScale = 100;

/// A declared ratio that sits below the floor its own pane declares — the
/// issue's reproduction.
const _kViolatingRatio = 0.3;

/// The floor [_kViolatingRatio] violates. Also serves as a floor that cannot
/// be satisfied alongside [_kViolatedCeiling] as a second pane's floor,
/// since the two together ask for 110% of the container.
const _kViolatingFloor = 0.5;

/// A ceiling a declared ratio of `0.9` overshoots — the mirror of
/// [_kViolatingFloor], exercising the opposite bound.
const _kViolatedCeiling = 0.6;

/// A pane wrapper's inline `flex` rule — `<flex> 1 0`, where `<flex>` is the
/// integer ratio the browser lays the panes out by. Reading it is how a test
/// sees the *rendered* fraction, as opposed to the announced one.
final _kPaneFlex = RegExp(r'^(\d+) 1 0$');

Iterable<DomComponent> _elements(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

Iterable<Map<String, String>> _dividerAttributes(ComponentTester tester) =>
    _elements(
          tester,
        )
        .map((c) => c.attributes ?? const {})
        .where((a) => a['role'] == 'separator');

int? _paneFlexOf(DomComponent component) {
  final flex = component.styles?.properties['flex'];
  if (flex == null) return null;
  final match = _kPaneFlex.firstMatch(flex);
  return match == null ? null : int.parse(match.group(1)!);
}

/// The fraction of the container each pane is actually laid out at.
///
/// This is the other half of the pair the issue is about: an `aria-valuenow`
/// is only true if it names the fraction the panes were drawn at, so every
/// assertion below reads both out of the same pumped tree.
List<double> _renderedRatios(ComponentTester tester) {
  final flexes = [
    for (final component in _elements(tester))
      if (_paneFlexOf(component) case final flex?) flex,
  ];
  final total = flexes.fold<int>(0, (sum, flex) => sum + flex);
  return [for (final flex in flexes) flex / total];
}

/// Asserts `aria-valuenow` lies inside `[aria-valuemin, aria-valuemax]` —
/// the completion condition stated verbatim, and the assertion an inverted
/// range fails first.
void _expectValueWithinBounds(Map<String, String> divider) {
  final now = int.parse(divider['aria-valuenow']!);
  final min = int.parse(divider['aria-valuemin']!);
  final max = int.parse(divider['aria-valuemax']!);
  expect(min, lessThanOrEqualTo(max), reason: 'announced range is inverted');
  expect(now, greaterThanOrEqualTo(min));
  expect(now, lessThanOrEqualTo(max));
  // The spoken sentence and the bare number are two renderings of one
  // position; letting them drift is how a reader announces a percentage the
  // control does not report.
  expect(
    divider['aria-valuetext'],
    DefaultCouiLocalizations.instance.resizableDividerPositionLabel(now),
  );
}

Resizable _resizable(
  List<({double size, double? min, double? max})> declared,
) => Resizable(
  panes: [
    for (final pane in declared)
      CoreResizablePaneData<Component>(
        content: div(const []),
        initialSize: pane.size,
        minSize: pane.min,
        maxSize: pane.max,
      ),
  ],
);

/// Rebuilds its child in place so the child reaches `didUpdateComponent`.
///
/// `ComponentTester.pumpComponent` mounts a fresh root instead of updating
/// the existing tree, so a second pump runs `initState` again — and a fresh
/// mount resolves whatever panes it is handed, which makes an assertion
/// about the *update* path pass without that path ever running. Swapping the
/// pane list from a parent's `setState` is the only shape that reaches it.
class _PaneSwapHost extends StatefulComponent {
  const _PaneSwapHost({required this.builder, required this.onState});

  /// Builds the resizable from the current swap flag.
  final Component Function(bool swapped) builder;

  /// Hands the live state back on every build, since `setState` is
  /// `@protected` and a test sits outside the component tree.
  final void Function(_PaneSwapHostState state) onState;

  @override
  State<_PaneSwapHost> createState() => _PaneSwapHostState();
}

class _PaneSwapHostState extends State<_PaneSwapHost> {
  bool swapped = false;

  void swap() => setState(() => swapped = true);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return component.builder(swapped);
  }
}

void main() {
  group('Resizable divider (WCAG 2.1.1, #3496)', () {
    testComponents('carries role=separator + tabindex=0', (tester) async {
      pumpWithTheme(
        tester,
        Resizable(
          panes: [
            CoreResizablePaneData<Component>(content: div(const [])),
            CoreResizablePaneData<Component>(content: div(const [])),
          ],
        ),
      );

      final dividers = _dividerAttributes(tester).toList();
      expect(dividers, hasLength(1));
      expect(dividers.first['tabindex'], '0');
    });

    testComponents(
      'aria-orientation is vertical for a horizontal split '
      '(vertical divider line, Left/Right resize it)',
      (tester) async {
        pumpWithTheme(
          tester,
          Resizable(
            panes: [
              CoreResizablePaneData<Component>(content: div(const [])),
              CoreResizablePaneData<Component>(content: div(const [])),
            ],
          ),
        );

        expect(
          _dividerAttributes(tester).first['aria-orientation'],
          'vertical',
        );
      },
    );

    testComponents(
      'aria-orientation is horizontal for a vertical split '
      '(horizontal divider line, Up/Down resize it)',
      (tester) async {
        pumpWithTheme(
          tester,
          Resizable(
            direction: CoreResizableDirection.vertical,
            panes: [
              CoreResizablePaneData<Component>(content: div(const [])),
              CoreResizablePaneData<Component>(content: div(const [])),
            ],
          ),
        );

        expect(
          _dividerAttributes(tester).first['aria-orientation'],
          'horizontal',
        );
      },
    );

    testComponents(
      'aria-valuenow/aria-valuetext reflect the actual pane ratio, not a '
      'hardcoded value',
      (tester) async {
        pumpWithTheme(
          tester,
          Resizable(
            panes: [
              CoreResizablePaneData<Component>(
                content: div(const []),
                initialSize: 0.3,
              ),
              CoreResizablePaneData<Component>(
                content: div(const []),
                initialSize: 0.7,
              ),
            ],
          ),
        );

        final divider = _dividerAttributes(tester).first;
        expect(divider['aria-valuenow'], '30');
        // Asserted through the locale's own formatter rather than a
        // literal: this test is about the number being read off live
        // `_sizes`, and hardcoding the sentence here would make a
        // wording change look like a broken ratio. The sentence itself
        // is pinned in `l10n_wiring_test.dart`.
        expect(
          divider['aria-valuetext'],
          DefaultCouiLocalizations.instance.resizableDividerPositionLabel(
            _kLeftPanePercent,
          ),
        );
      },
    );

    testComponents(
      'a different initial ratio produces a different aria-valuenow — '
      'proves the value is computed, not a static string',
      (tester) async {
        pumpWithTheme(
          tester,
          Resizable(
            panes: [
              CoreResizablePaneData<Component>(
                content: div(const []),
                initialSize: 0.65,
              ),
              CoreResizablePaneData<Component>(
                content: div(const []),
                initialSize: 0.35,
              ),
            ],
          ),
        );

        expect(_dividerAttributes(tester).first['aria-valuenow'], '65');
      },
    );

    testComponents(
      'aria-valuemin/aria-valuemax reflect the left pane minSize/maxSize',
      (tester) async {
        pumpWithTheme(
          tester,
          Resizable(
            panes: [
              CoreResizablePaneData<Component>(
                content: div(const []),
                initialSize: 0.5,
                minSize: 0.2,
                maxSize: 0.8,
              ),
              CoreResizablePaneData<Component>(content: div(const [])),
            ],
          ),
        );

        final divider = _dividerAttributes(tester).first;
        expect(divider['aria-valuemin'], '20');
        expect(divider['aria-valuemax'], '80');
      },
    );
  });

  // Each case gets its own `testComponents`. Pumping a second pane list
  // inside one test reuses the same `State`, so `initState` does not run
  // again and the second case reads the first one's sizes — a property worth
  // testing on its own (it is, at the end of this group), not a way to write
  // the others.
  group('initialSize normalisation (#4050)', () {
    testComponents(
      'a ratio below its own minSize is announced at the fraction it is '
      'laid out at',
      (tester) async {
        pumpWithTheme(
          tester,
          _resizable([
            (size: _kViolatingRatio, min: _kViolatingFloor, max: null),
            (size: 0.7, min: null, max: null),
          ]),
        );

        final rendered = _renderedRatios(tester);
        final divider = _dividerAttributes(tester).first;

        // Announcing 30% over a layout drawn at 50% is the half of this
        // issue the Web twin showed; announcing a clamped 50% over a layout
        // still drawn at 30% was the other half, on Flutter. Reading both
        // numbers here is what rejects either.
        expect(
          divider['aria-valuenow'],
          '${(rendered.first * _kPercentScale).round()}',
        );
        expect(rendered.first, closeTo(0.5, 0.001));
        _expectValueWithinBounds(divider);
      },
    );

    testComponents('a ratio above its own maxSize gets the same treatment', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _resizable([
          (size: 0.9, min: null, max: _kViolatedCeiling),
          (size: 0.1, min: null, max: null),
        ]),
      );

      final rendered = _renderedRatios(tester);
      final divider = _dividerAttributes(tester).first;

      expect(
        divider['aria-valuenow'],
        '${(rendered.first * _kPercentScale).round()}',
      );
      expect(rendered.first, closeTo(_kViolatedCeiling, 0.001));
      _expectValueWithinBounds(divider);
    });

    testComponents(
      'ratios that do not add up to the container are announced at the '
      'fraction they are laid out at',
      (tester) async {
        // No bound is violated — the ratios simply miss the whole. The
        // layout normalises by their total while the announcement read them
        // as fractions of the container, so a test that only picks sums of
        // 1 never sees this.
        pumpWithTheme(
          tester,
          _resizable([
            (size: _kViolatingRatio, min: null, max: null),
            (size: _kViolatingRatio, min: null, max: null),
          ]),
        );

        final rendered = _renderedRatios(tester);
        expect(rendered.first, closeTo(0.5, 0.001));
        expect(
          _dividerAttributes(tester).first['aria-valuenow'],
          '${(rendered.first * _kPercentScale).round()}',
        );
      },
    );

    testComponents(
      'a middle pane whose minSize exceeds its share leaves every divider '
      'range the right way round',
      (tester) async {
        // The shape that made the Flutter twin throw out of `LayoutBuilder`.
        // Web has no clamp to assert on, so it emitted
        // `aria-valuemin="0" aria-valuemax="-10"` instead — a negative,
        // inverted range.
        pumpWithTheme(
          tester,
          _resizable([
            (size: 0.2, min: null, max: null),
            (size: 0.2, min: _kViolatingFloor, max: null),
            (size: 0.6, min: null, max: null),
          ]),
        );

        final dividers = _dividerAttributes(tester).toList();
        expect(dividers, hasLength(2));
        for (final divider in dividers) {
          _expectValueWithinBounds(divider);
        }
      },
    );

    testComponents(
      'two minSizes that cannot both fit still produce a valid range',
      (tester) async {
        // `min: .5` + `min: .6` asks for 110% of the container: no sizes
        // satisfy both, so reporting the floors unchanged left
        // `aria-valuemin` above `aria-valuemax` however the sizes moved.
        pumpWithTheme(
          tester,
          _resizable([
            (size: 0.5, min: _kViolatingFloor, max: null),
            (size: 0.5, min: _kViolatedCeiling, max: null),
          ]),
        );

        _expectValueWithinBounds(_dividerAttributes(tester).first);
      },
    );

    testComponents('the laid-out flexes add up to the whole container', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _resizable([
          (size: _kViolatingRatio, min: _kViolatingFloor, max: null),
          (size: _kViolatingRatio, min: null, max: null),
        ]),
      );

      // A per-pane clamp turns the invalid range green while leaving the
      // sizes summing to more than the container — which is the
      // announce-vs-render split this issue is about. Both numbers have to
      // move together.
      final rendered = _renderedRatios(tester);
      expect(rendered.fold<double>(0, (sum, r) => sum + r), closeTo(1, 0.001));
      expect(
        _dividerAttributes(tester).first['aria-valuenow'],
        '${(rendered.first * _kPercentScale).round()}',
      );
    });

    testComponents(
      'a pane list swapped at runtime is normalised against its own bounds',
      (tester) async {
        late _PaneSwapHostState host;
        pumpWithTheme(
          tester,
          _PaneSwapHost(
            onState: (state) => host = state,
            builder: (swapped) => _resizable([
              (size: 0.5, min: swapped ? 0.8 : null, max: null),
              (size: 0.5, min: null, max: null),
            ]),
          ),
        );

        expect(_renderedRatios(tester).first, closeTo(0.5, 0.001));

        // Sizes resolved once at mount go on satisfying the bounds of a pane
        // list that no longer exists — the same out-of-range announcement,
        // reintroduced one rebuild later.
        host.swap();
        await tester.pump();

        expect(_renderedRatios(tester).first, closeTo(0.8, 0.001));
        _expectValueWithinBounds(_dividerAttributes(tester).first);
      },
    );

    testComponents('a rebuild that changes only content keeps the sizes', (
      tester,
    ) async {
      late _PaneSwapHostState host;
      pumpWithTheme(
        tester,
        _PaneSwapHost(
          onState: (state) => host = state,
          builder: (swapped) => Resizable(
            panes: [
              CoreResizablePaneData<Component>(
                content: div([Component.text(swapped ? 'after' : 'before')]),
                initialSize: _kViolatingRatio,
              ),
              CoreResizablePaneData<Component>(
                content: div(const []),
                initialSize: 0.7,
              ),
            ],
          ),
        ),
      );

      final before = _renderedRatios(tester);

      // Re-resolving on every rebuild would throw away sizes the user
      // dragged to. Only a changed *geometry* is a new declaration.
      host.swap();
      await tester.pump();

      expect(_renderedRatios(tester), before);
      expect(find.text('after'), findsOneComponent);
    });
  });
}
