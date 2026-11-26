// The two pulse colours Web's Skeleton emits (`--pulse-from` / `--pulse-to`)
// compared against the vector table coui_core owns — the same numbers the
// Flutter test reads off its painted decoration.
//
// The pulse opacity is multiplied into the fill's own alpha, so a
// transparent fill stays transparent and a fill at 40% rests at 20%.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const String kSkeletonPulseVectorsPath =
    '../coui_core/test/fixtures/skeleton_pulse_vectors.json';

/// The tokens the vector table names — `CoreColors` has no lookup by name.
const Map<String, CoreColorToken> _kTokens = {'primary': CoreColors.primary};

/// What the emitted CSS text can say, not a difference in the composition:
/// a token's alpha is written as a whole percent (truncated) and a raw
/// colour's as two decimals, so `26/255` reaches the page as `0.10`. Both
/// platforms compose the same number; Web's text rounds it.
const double _kCssTextPrecision = 0.01;

const String _kWidth = '200px';
const String _kHeight = '20px';

final RegExp _tokenColor = RegExp(
  r'^rgb\(var\(--coui-([a-z-]+)\)(?: / (\d+)%)?\)$',
);
final RegExp _rawColor = RegExp(
  r'^rgba?\(\d+, \d+, \d+(?:, ([0-9.]+))?\)$',
);

/// The alpha a pulse colour paints with, and the token it reads (if any).
({double alpha, String? token}) _parse(String css) {
  final token = _tokenColor.firstMatch(css);
  if (token != null) {
    final pct = token.group(2);
    return (
      alpha: pct == null ? 1.0 : int.parse(pct) / 100,
      token: token.group(1),
    );
  }
  final raw = _rawColor.firstMatch(css);
  if (raw != null) {
    final alpha = raw.group(1);
    return (alpha: alpha == null ? 1.0 : double.parse(alpha), token: null);
  }
  throw FormatException('not a pulse colour', css);
}

CoreColor? _fill(Map<String, Object?>? spec) {
  if (spec == null) return null;
  final argb = spec['argb'] as String?;
  if (argb != null) return CoreColor(int.parse(argb));

  return CoreColor.token(
    _kTokens[spec['token']]!,
    opacity: (spec['opacity']! as num).toDouble(),
  );
}

void _expectAlpha(double actual, double expected, String end) {
  // Nothing to round at zero: a transparent end must be exactly clear.
  if (expected == 0) {
    expect(actual, 0, reason: end);
    return;
  }
  expect(actual, closeTo(expected, _kCssTextPrecision), reason: end);
}

void main() {
  final doc =
      jsonDecode(File(kSkeletonPulseVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
  });

  final timelines =
      ((doc['timelines']! as Map<String, Object?>)['cases']! as List)
          .cast<Map<String, Object?>>();
  final themeCss = ThemeConfig.defaults().cssVariables;

  // The same timeline Flutter's controller is sampled against. A browser
  // runs it from three facts this side emits — the period, the curve and
  // the keyframe layout — so those are what is pinned here.
  group('the pulse follows the shared timeline', () {
    test('keyframes: rest at 0% and 100%, peak at 50%', () {
      final keyframes = [
        '@keyframes $kSkeletonPulseAnimationName{',
        '0%,100%{background-color:var(--pulse-from)}',
        '50%{background-color:var(--pulse-to)}',
        '}',
      ].join();
      expect(themeCss, contains(keyframes));
    });

    for (final c in timelines) {
      testComponents('${c['name']}: period and curve', (tester) async {
        final period = Duration(milliseconds: c['periodMs']! as int);
        final l = (c['curve']! as List).cast<num>();
        final curve = (
          x1: l[0].toDouble(),
          y1: l[1].toDouble(),
          x2: l[2].toDouble(),
          y2: l[3].toDouble(),
        );
        // The default case runs on the defaults, so it pins them too.
        pumpWithTheme(
          tester,
          Skeleton(
            width: _kWidth,
            height: _kHeight,
            skeletonStyle: c['name'] == 'default'
                ? null
                : CoreSkeletonStyle(duration: period, curve: curve),
          ),
        );

        final styles = find
            .byType(DomComponent)
            .evaluate()
            .map((e) => (e.component as DomComponent).styles?.properties)
            .whereType<Map<String, String>>()
            .firstWhere((props) => props.containsKey('--pulse-from'));
        expect(styles['animation-duration'], '${period.inMilliseconds}ms');
        expect(
          _bezierOf(styles['animation-timing-function']!, themeCss),
          [curve.x1, curve.y1, curve.x2, curve.y2],
        );
      });
    }
  });

  for (final c in cases) {
    testComponents('${c['name']}: rest ${c['restAlpha']}, '
        'peak ${c['peakAlpha']}', (tester) async {
      final fill = _fill(c['fill'] as Map<String, Object?>?);
      pumpWithTheme(
        tester,
        Skeleton(
          width: _kWidth,
          height: _kHeight,
          skeletonStyle: CoreSkeletonStyle(
            backgroundColor: fill,
            fromOpacity: (c['fromOpacity']! as num).toDouble(),
            toOpacity: (c['toOpacity']! as num).toDouble(),
          ),
        ),
      );

      final styles = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => (e.component as DomComponent).styles?.properties)
          .whereType<Map<String, String>>()
          .firstWhere((props) => props.containsKey('--pulse-from'));
      final rest = _parse(styles['--pulse-from']!);
      final peak = _parse(styles['--pulse-to']!);

      _expectAlpha(rest.alpha, (c['restAlpha']! as num).toDouble(), 'rest');
      _expectAlpha(peak.alpha, (c['peakAlpha']! as num).toDouble(), 'peak');

      // A token fill keeps its token at both ends — dark mode keeps tracking
      // through the animation.
      final expectedToken = fill == null
          ? CoreSkeletonStyle
                .defaultsByVariant[CoreSkeletonVariant.defaultVariant]!
                .backgroundColor
                .token
                ?.name
          : fill.token?.name;
      expect(rest.token, expectedToken);
      expect(peak.token, expectedToken);
    });
  }
}

final RegExp _easingVar = RegExp(r'^var\(--easing-([A-Za-z0-9-]+)\)$');
final RegExp _bezier = RegExp(
  r'cubic-bezier\(([-0-9.]+), ([-0-9.]+), ([-0-9.]+), ([-0-9.]+)\)',
);

/// The four control points a `animation-timing-function` value runs — read
/// through its `--easing-*` variable when it names one, the way the browser
/// would.
List<double> _bezierOf(String timing, String css) {
  final name = _easingVar.firstMatch(timing)?.group(1);
  final source = name == null
      ? timing
      : RegExp('--easing-$name:([^;]+);').firstMatch(css)!.group(1)!;
  final m = _bezier.firstMatch(source)!;
  return [for (var i = 1; i <= 4; i++) double.parse(m.group(i)!)];
}
