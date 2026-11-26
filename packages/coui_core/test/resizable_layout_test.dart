import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// Sizes that add up to anything other than this render at a fraction of
/// what they announce: the layout divides them by their own total while the
/// announced percentage reads them as fractions of the container.
const _kWhole = 1.0;

/// Ratios are compared at a tolerance far below the percentage the panes
/// are announced at, so rounding never decides whether an invariant holds.
const _kEpsilon = 1e-9;

/// Panes carrying no content — this file is about the numbers only.
List<CoreResizablePaneData<Object>> _panes(
  List<({double size, double? min, double? max})> declared,
) => [
  for (final pane in declared)
    CoreResizablePaneData<Object>(
      content: const Object(),
      initialSize: pane.size,
      minSize: pane.min,
      maxSize: pane.max,
    ),
];

double _total(List<double> values) =>
    values.fold<double>(0, (sum, value) => sum + value);

/// Asserts the three invariants every consumer depends on, whatever was
/// declared: sizes fill the container, each sits inside its own resolved
/// bounds, and every divider's range contains the position that divider
/// reports.
void _expectInvariants(CoreResizableLayout layout) {
  expect(_total(layout.sizes), closeTo(_kWhole, _kEpsilon));
  for (var i = 0; i < layout.sizes.length; i++) {
    expect(
      layout.sizes[i],
      greaterThanOrEqualTo(layout.minSizes[i] - _kEpsilon),
      reason: 'pane $i fell below its resolved floor',
    );
    expect(
      layout.sizes[i],
      lessThanOrEqualTo(layout.maxSizes[i] + _kEpsilon),
      reason: 'pane $i rose above its resolved ceiling',
    );
  }
  for (var i = 0; i < layout.sizes.length - 1; i++) {
    final range = layout.dividerRange(i);
    expect(
      range.min,
      lessThanOrEqualTo(range.max),
      reason: 'divider $i reported an inverted range',
    );
    expect(range.now, greaterThanOrEqualTo(range.min - _kEpsilon));
    expect(range.now, lessThanOrEqualTo(range.max + _kEpsilon));
  }
}

void main() {
  group('CoreResizableLayout.resolve', () {
    test('normalises declared ratios that miss the whole container', () {
      // Nothing here is out of bounds — the ratios simply do not add up, and
      // that alone is enough to make a pane render at half the container
      // while announcing 30%.
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.3, min: null, max: null),
          (size: 0.3, min: null, max: null),
        ]),
      );

      expect(layout.sizes, [closeTo(0.5, _kEpsilon), closeTo(0.5, _kEpsilon)]);
      _expectInvariants(layout);
    });

    test('keeps the declared proportions while normalising', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.1, min: null, max: null),
          (size: 0.3, min: null, max: null),
        ]),
      );

      expect(layout.sizes, [
        closeTo(0.25, _kEpsilon),
        closeTo(0.75, _kEpsilon),
      ]);
      _expectInvariants(layout);
    });

    test('lifts a ratio below its own floor and bills the neighbour', () {
      // The issue's reproduction: left declares 30% but will not go under
      // 50%. Clamping alone would leave the sizes adding up to 1.2 — the
      // space has to come from somewhere, and it comes from the pane that
      // has slack.
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.3, min: 0.5, max: null),
          (size: 0.7, min: null, max: null),
        ]),
      );

      expect(layout.sizes, [closeTo(0.5, _kEpsilon), closeTo(0.5, _kEpsilon)]);
      _expectInvariants(layout);

      final range = layout.dividerRange(0);
      expect(range.now, closeTo(0.5, _kEpsilon));
      expect(range.min, closeTo(0.5, _kEpsilon));
      expect(range.max, closeTo(_kWhole, _kEpsilon));
    });

    test('pulls a ratio above its own ceiling down and pays the neighbour', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.9, min: null, max: 0.6),
          (size: 0.1, min: null, max: null),
        ]),
      );

      expect(layout.sizes, [closeTo(0.6, _kEpsilon), closeTo(0.4, _kEpsilon)]);
      _expectInvariants(layout);

      final range = layout.dividerRange(0);
      expect(range.min, closeTo(0, _kEpsilon));
      expect(range.max, closeTo(0.6, _kEpsilon));
    });

    test(
      'a middle pane whose floor exceeds its share leaves every divider '
      'range the right way round (the 3-pane render crash)',
      () {
        // `[0.2 | 0.2 min .5 | 0.6]` used to make divider 0 report
        // `min: 0.0, max: -0.1`, and `num.clamp` asserts on an inverted
        // range rather than returning anything — so the widget threw out of
        // `LayoutBuilder` instead of rendering.
        final layout = CoreResizableLayout.resolve(
          _panes([
            (size: 0.2, min: null, max: null),
            (size: 0.2, min: 0.5, max: null),
            (size: 0.6, min: null, max: null),
          ]),
        );

        _expectInvariants(layout);
        expect(layout.sizes[1], closeTo(0.5, _kEpsilon));
      },
    );

    test(
      'floors that cannot fit together are relaxed proportionally '
      '(the 2-pane render crash)',
      () {
        // `.5 min .5 | .5 min .6` asks for 110% of the container. No set of
        // sizes satisfies both floors, so reporting them unchanged is what
        // left `aria-valuemin` above `aria-valuemax` no matter what the
        // sizes did.
        final layout = CoreResizableLayout.resolve(
          _panes([
            (size: 0.5, min: 0.5, max: null),
            (size: 0.5, min: 0.6, max: null),
          ]),
        );

        _expectInvariants(layout);
        expect(_total(layout.minSizes), closeTo(_kWhole, _kEpsilon));
        // Relaxed in proportion to what was asked for, not by dropping one.
        expect(
          layout.minSizes[1] / layout.minSizes[0],
          closeTo(1.2, _kEpsilon),
        );
      },
    );

    test('ceilings that cannot fill the container are relaxed too', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.5, min: null, max: 0.1),
          (size: 0.5, min: null, max: 0.1),
        ]),
      );

      _expectInvariants(layout);
      expect(
        _total(layout.maxSizes),
        greaterThanOrEqualTo(_kWhole - _kEpsilon),
      );
    });

    test('a ceiling below its own floor yields to it', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.5, min: 0.6, max: 0.4),
          (size: 0.5, min: null, max: null),
        ]),
      );

      _expectInvariants(layout);
      expect(layout.sizes[0], closeTo(0.6, _kEpsilon));
    });

    test('ratios carrying no information become an even split', () {
      for (final declared in <List<double>>[
        [0, 0, 0],
        [-1, -1, -1],
        [double.nan, double.infinity, 0],
      ]) {
        final layout = CoreResizableLayout.resolve(
          _panes([
            for (final size in declared) (size: size, min: null, max: null),
          ]),
        );
        _expectInvariants(layout);
        for (final size in layout.sizes) {
          expect(size, closeTo(1 / 3, _kEpsilon));
        }
      }
    });

    test('bounds outside [0, 1] are pulled into the container', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.5, min: -2, max: 5),
          (size: 0.5, min: null, max: null),
        ]),
      );

      _expectInvariants(layout);
      expect(layout.minSizes.first, 0);
      expect(layout.maxSizes.first, _kWhole);
    });

    test('an empty pane list resolves to an empty layout', () {
      final layout = CoreResizableLayout.resolve(
        <CoreResizablePaneData<Object>>[],
      );
      expect(layout.sizes, isEmpty);
      expect(layout.minSizes, isEmpty);
      expect(layout.maxSizes, isEmpty);
    });
  });

  group('CoreResizableLayout.moveDivider', () {
    test('spends the delta between the two adjacent panes only', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.25, min: null, max: null),
          (size: 0.25, min: null, max: null),
          (size: 0.5, min: null, max: null),
        ]),
      );

      final moved = layout.moveDivider(0, 0.1);

      expect(moved, isNotNull);
      expect(moved!.sizes[0], closeTo(0.35, _kEpsilon));
      expect(moved.sizes[1], closeTo(0.15, _kEpsilon));
      expect(moved.sizes[2], closeTo(0.5, _kEpsilon));
      _expectInvariants(moved);
    });

    test('clamps an overshoot to the bound instead of dropping the move', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.5, min: null, max: 0.6),
          (size: 0.5, min: null, max: null),
        ]),
      );

      final moved = layout.moveDivider(0, 0.4);

      expect(moved, isNotNull);
      expect(moved!.sizes[0], closeTo(0.6, _kEpsilon));
      _expectInvariants(moved);
    });

    test('returns null once the divider is already at the bound', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.6, min: null, max: 0.6),
          (size: 0.4, min: null, max: null),
        ]),
      );

      expect(layout.moveDivider(0, 0.1), isNull);
      expect(layout.moveDivider(0, double.nan), isNull);
    });

    test(
      'a divider whose declared ratio violated its floor still moves by one '
      'keyboard step (the frozen-divider regression)',
      () {
        // Before the sizes were resolved, `_sizes[0]` sat at 0.3 against a
        // floor of 0.5, and every step small enough to stay a keyboard step
        // landed short of the floor and was rejected — so the divider was
        // reachable by Tab and could not be moved by any number of presses.
        final layout = CoreResizableLayout.resolve(
          _panes([
            (size: 0.3, min: 0.5, max: null),
            (size: 0.7, min: null, max: null),
          ]),
        );

        const step = CoreResizableContract.defaultKeyboardStepFraction;
        final moved = layout.moveDivider(0, step);

        expect(moved, isNotNull);
        expect(moved!.sizes[0], closeTo(0.5 + step, _kEpsilon));
        _expectInvariants(moved);
      },
    );

    test('carries the resolved bounds forward so later moves keep them', () {
      final layout = CoreResizableLayout.resolve(
        _panes([
          (size: 0.5, min: 0.4, max: null),
          (size: 0.5, min: 0.4, max: null),
        ]),
      );

      var moved = layout;
      for (var press = 0; press < 100; press++) {
        moved = moved.moveDivider(0, -0.05) ?? moved;
      }

      expect(moved.sizes[0], closeTo(0.4, _kEpsilon));
      _expectInvariants(moved);
    });
  });

  group('CoreResizableLayout.declaresSameGeometry', () {
    test('content-only rebuilds are the same geometry', () {
      expect(
        CoreResizableLayout.declaresSameGeometry(
          _panes([
            (size: 0.3, min: 0.1, max: 0.9),
            (size: 0.7, min: null, max: null),
          ]),
          _panes([
            (size: 0.3, min: 0.1, max: 0.9),
            (size: 0.7, min: null, max: null),
          ]),
        ),
        isTrue,
      );
    });

    test('any changed ratio or bound is a different geometry', () {
      final before = _panes([
        (size: 0.3, min: 0.1, max: 0.9),
        (size: 0.7, min: null, max: null),
      ]);

      expect(
        CoreResizableLayout.declaresSameGeometry(
          before,
          _panes([
            (size: 0.4, min: 0.1, max: 0.9),
            (size: 0.6, min: null, max: null),
          ]),
        ),
        isFalse,
      );
      expect(
        CoreResizableLayout.declaresSameGeometry(
          before,
          _panes([
            (size: 0.3, min: 0.2, max: 0.9),
            (size: 0.7, min: null, max: null),
          ]),
        ),
        isFalse,
      );
      expect(
        CoreResizableLayout.declaresSameGeometry(
          before,
          _panes([
            (size: 0.3, min: 0.1, max: null),
            (size: 0.7, min: null, max: null),
          ]),
        ),
        isFalse,
      );
      expect(
        CoreResizableLayout.declaresSameGeometry(
          before,
          _panes([
            (size: 0.3, min: 0.1, max: 0.9),
            (size: 0.4, min: null, max: null),
            (size: 0.3, min: null, max: null),
          ]),
        ),
        isFalse,
      );
    });
  });
}
