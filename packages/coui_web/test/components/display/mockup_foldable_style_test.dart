// Where the Web `MockupFoldable` draws each part of the device, and how dark.
//
// The Web does not hand the browser Core's matrices: the bodies are sized in
// `rem`, so the placement is written as CSS transform functions in `rem` —
// the steps `CoreMockupFoldPose` names — and the browser multiplies them.
// Nothing guarantees a list of functions is the matrix it stands for, so this
// file multiplies the emitted list out the way a browser does and compares
// where each part's corners land with the table Core, Flutter and the Web
// share (`coui_core/test/fixtures/mockup_fold_vectors.json` — derived with
// plain trigonometry, independently of any matrix code).
//
// The same goes for how a slab's edge ends. The table states the cut in the
// edge's own box; the Web writes it as a box, its side and its corners, in
// terms of the radius variables, so this file reads those back as a browser
// would at the variables the kit's stylesheet states.
//
// What a browser paints from either is not provable here; that is seen in
// Chrome.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The table shared with Core and Flutter (cwd is `packages/coui_web` under
/// `dart test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/mockup_fold_vectors.json';

/// How far a corner may land from the table (logical px): the resolver keeps
/// five decimals of a `rem` and six of a radian, and the camera magnifies
/// what is near.
const double _kCornerTolerance = 0.01;

/// The root font size every `rem` is read at unless a test says otherwise.
const double _kRootFont = 16;

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

BuildContext _contextUnder(
  ComponentTester tester,
  CoreComponentTheme componentTheme,
) {
  late BuildContext context;
  tester.pumpComponent(
    Theme(
      data: ThemeData.coui.copyWith(coreComponentTheme: componentTheme),
      child: _ContextCapture((c) => context = c),
    ),
  );

  return context;
}

/// The resolver as the component calls it when the caller states no flag:
/// both of the island's flags at the contract's defaults.
ResolvedMockupFoldable _resolve(
  BuildContext context, {
  required double widgetWidth,
  required double foldAngle,
  bool showCamera = CoreMockupFoldableContract.defaultShowCamera,
  bool showStatus = CoreMockupFoldableContract.defaultShowStatus,
  CoreMockupFoldableStyle? mockupFoldableStyle,
}) => resolveMockupFoldable(
  context,
  widgetWidth: widgetWidth,
  foldAngle: foldAngle,
  showCamera: showCamera,
  showStatus: showStatus,
  mockupFoldableStyle: mockupFoldableStyle,
);

/// The shared layout as the resolver computes it: the island's lengths are
/// [style]'s, or the style's defaults where it states none.
CoreMockupFoldableLayout _layout({
  required double width,
  required CoreMockupDeviceStyle innerDeviceStyle,
  required CoreMockupDeviceStyle coverDeviceStyle,
  required double thickness,
  required double perspective,
  CoreMockupFoldableStyle? style,
}) => CoreMockupFoldableLayout.compute(
  width: width,
  innerDeviceStyle: innerDeviceStyle,
  coverDeviceStyle: coverDeviceStyle,
  thickness: thickness,
  perspective: perspective,
  islandWidth: style?.islandWidth ?? CoreMockupFoldableStyle.defaultIslandWidth,
  islandOffset:
      style?.islandOffset ?? CoreMockupFoldableStyle.defaultIslandOffset,
  islandCameraSize:
      style?.islandCameraSize ??
      CoreMockupFoldableStyle.defaultIslandCameraSize,
);

// ─── A browser's reading of a transform list ─────────────────
// 4 × 4, column-major like Core's: element (row, column) is at
// `column * 4 + row`.

List<double> _identity() => [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

List<double> _multiply(List<double> a, List<double> b) {
  final out = List<double>.filled(16, 0);
  for (var column = 0; column < 4; column++) {
    for (var row = 0; row < 4; row++) {
      var sum = 0.0;
      for (var k = 0; k < 4; k++) {
        sum += a[k * 4 + row] * b[column * 4 + k];
      }
      out[column * 4 + row] = sum;
    }
  }

  return out;
}

List<double> _translation(double x, double y, double z) => _identity()
  ..[12] = x
  ..[13] = y
  ..[14] = z;

/// CSS `rotateY(a)`: `matrix3d(cos, 0, -sin, 0, 0, 1, 0, 0, sin, 0, cos, 0,
/// 0, 0, 0, 1)`.
List<double> _rotateY(double radians) {
  final c = math.cos(radians);
  final s = math.sin(radians);

  return [c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1];
}

/// CSS `perspective(d)`: the identity with `-1/d` in the fourth row of the
/// third column.
List<double> _perspective(double distance) => _identity()..[11] = -1 / distance;

/// A CSS length the resolver may write inside a transform: `rem`, or a bare
/// zero. Anything else — a `px` above all — fails the test that reads it.
double _length(String text, double rootFont) {
  final value = text.trim();
  if (value == '0') return 0;
  if (!value.endsWith('rem')) {
    throw FormatException('a transform length that is not rem: "$value"');
  }

  return double.parse(value.substring(0, value.length - 3)) * rootFont;
}

double _angle(String text) {
  final value = text.trim();
  if (value.endsWith('rad')) {
    return double.parse(value.substring(0, value.length - 3));
  }
  if (value.endsWith('deg')) {
    return double.parse(value.substring(0, value.length - 3)) * math.pi / 180;
  }
  throw FormatException('an angle that is neither rad nor deg: "$value"');
}

/// The matrix a browser builds from [transform]: each function's matrix,
/// multiplied left to right.
List<double> _matrixOf(String transform, {double rootFont = _kRootFont}) {
  var matrix = _identity();
  final functions = RegExp(r'([a-zA-Z0-9]+)\(([^)]*)\)').allMatches(transform);
  final consumed = functions.map((m) => m.group(0)!).join(' ');
  if (consumed != transform.trim()) {
    throw FormatException('not a list of transform functions: "$transform"');
  }
  for (final function in functions) {
    final arguments = function.group(2)!.split(',');
    double length(int index) => _length(arguments[index], rootFont);
    final step = switch (function.group(1)!) {
      'translateX' => _translation(length(0), 0, 0),
      'translateZ' => _translation(0, 0, length(0)),
      'translate' => _translation(length(0), length(1), 0),
      'translate3d' => _translation(length(0), length(1), length(2)),
      'rotateY' => _rotateY(_angle(arguments.first)),
      'perspective' => _perspective(length(0)),
      final name => throw FormatException('unexpected function "$name"'),
    };
    matrix = _multiply(matrix, step);
  }

  return matrix;
}

/// How far away the camera of [transform] stands (logical px).
double _cameraDistance(String transform) => _length(
  RegExp(r'perspective\(([^)]*)\)').firstMatch(transform)!.group(1)!,
  _kRootFont,
);

/// How far a layer may stand from the strength it was given: a CSS colour
/// keeps its alpha to a hundredth.
const double _kAlphaStep = 0.01;

/// The alpha of a CSS colour the adapter writes: `rgb(r, g, b)` and
/// `rgb(var(--x))` are opaque, `rgba(r, g, b, a)` states it as a share and
/// `rgb(var(--x) / N%)` as a percentage.
double _alphaOf(String css) {
  final percent = RegExp(r'/ ([0-9.]+)%\)$').firstMatch(css);
  if (percent != null) return double.parse(percent.group(1)!) / 100;
  final share = RegExp(r'^rgba\(.*, ([0-9.]+)\)$').firstMatch(css);
  if (share != null) return double.parse(share.group(1)!);
  if (css.startsWith('rgb(')) return 1;
  throw FormatException('not a colour the adapter writes: "$css"');
}

/// How much of its fill a layer shows.
double _strength(WebElementChrome chrome) =>
    _alphaOf(_style(chrome, 'background-color'));

String _style(WebElementChrome chrome, String property) =>
    chrome.inlineStyles!.properties[property]!;

double _rem(String value) =>
    double.parse(value.substring(0, value.length - 3)) * _kRootFont;

bool _has(WebElementChrome chrome, String className) =>
    chrome.className.split(' ').contains(className);

/// The four corners of a box [width] × [height] under [matrix]: top-left,
/// top-right, bottom-left, bottom-right — the table's order.
List<({double x, double y})> _corners(
  List<double> matrix,
  double width,
  double height,
) => [
  CoreMockupFoldPose.project(matrix, 0, 0),
  CoreMockupFoldPose.project(matrix, width, 0),
  CoreMockupFoldPose.project(matrix, 0, height),
  CoreMockupFoldPose.project(matrix, width, height),
];

// ─── A browser's reading of how an edge ends ─────────────────

/// How far a cut may stand from the table (logical px). The resolver keeps
/// five decimals of the number a corner is multiplied by, and the table six
/// of a pixel.
const double _kCutTolerance = 0.001;

/// How far, as a share of itself, a cut scaled with its corner may stand
/// from the cut the shared rule makes for the corner it was scaled to.
const double _kMovedCutShare = 0.0025;

/// [text] cut at each [separator] that is not inside parentheses.
List<String> _split(String text, String separator) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (depth == 0 && char == separator) {
      parts.add(text.substring(start, i));
      start = i + 1;
    }
  }

  return parts..add(text.substring(start));
}

/// A length an edge is written with, in px: `rem` at the 16px root, `px`, a
/// reference to a variable as [variables] state it, a `calc()` multiplying
/// one of those by a number, or the `max()` of several.
double _px(String css, Map<String, double> variables) {
  final text = css.trim();
  String inside(String function) =>
      text.substring(function.length + 1, text.length - 1);

  if (text.startsWith('max(') && text.endsWith(')')) {
    return _split(
      inside('max'),
      ',',
    ).map((part) => _px(part, variables)).reduce(math.max);
  }
  if (text.startsWith('calc(') && text.endsWith(')')) {
    final product = _split(inside('calc'), '*');
    if (product.length != 2) {
      throw FormatException('not a length times a number: "$css"');
    }

    return _px(product.first, variables) * double.parse(product.last.trim());
  }
  if (text.startsWith('var(') && text.endsWith(')')) {
    final value = variables[inside('var')];
    if (value == null) throw StateError('no such variable: "$css"');

    return value;
  }
  if (text.endsWith('rem')) return _rem(text);
  if (text.endsWith('px')) {
    return double.parse(text.substring(0, text.length - 2));
  }
  throw FormatException('not a length an edge is written with: "$css"');
}

/// The px each `--coui-radius-*` variable states in the kit's stylesheet: on
/// the root and, where [under] names a selector, as the rule under it
/// re-points them — what a browser reads a reference to one as.
Map<String, double> _radiusVariables({String? under}) {
  final css = ThemeConfig.defaults().cssVariables;
  final root = <String, double>{};
  final moved = <String, double>{};
  final declaration = RegExp(r'(--coui-radius-\d+):\s*([0-9.]+)px');
  for (final match in declaration.allMatches(css)) {
    final open = css.lastIndexOf('{', match.start);
    final selector = css.substring(css.lastIndexOf('}', open) + 1, open).trim();
    final value = double.parse(match.group(2)!);
    if (selector == ':root') root.putIfAbsent(match.group(1)!, () => value);
    if (selector == under) moved[match.group(1)!] = value;
  }

  return {...root, ...moved};
}

/// The corner [fill] rounds at its [end] (`top` / `bottom`) on its [side]
/// (`left` / `right`): how far across and how far down, in px. `null` where
/// it states none.
({double x, double y})? _corner(
  WebElementChrome fill,
  String end,
  String side,
  Map<String, double> variables,
) {
  final value = fill.inlineStyles!.properties['border-$end-$side-radius'];
  if (value == null) return null;
  final radii = _split(value, ' ');
  expect(radii, hasLength(2), reason: value);

  return (x: _px(radii.first, variables), y: _px(radii.last, variables));
}

/// Every radius [fill] states, by property.
Map<String, String> _radii(WebElementChrome fill) => {
  for (final entry in fill.inlineStyles!.properties.entries)
    if (entry.key.endsWith('-radius')) entry.key: entry.value,
};

/// A corner as far across as it is down.
CoreMockupFoldCorner _round(double radius) => (x: radius, y: radius);

/// The variable the radius scale's step [radius] is stated with.
String _radiusVariable(double radius) => '--coui-radius-${radius.toInt()}';

/// The geometry of the shared table, stated as a style: at this width the
/// default open body is not the table's height, so the inner screen's
/// proportions are set to the ones that leave exactly that body.
CoreMockupFoldableStyle _tableStyle({
  required double width,
  required double height,
  required double thickness,
  required double perspective,
}) {
  final probe = _layout(
    width: width,
    innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
    coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
    thickness: thickness,
    perspective: perspective,
  );
  final inset = probe.innerScreen.left;

  return CoreMockupFoldableStyle(
    thickness: thickness,
    perspective: perspective,
    innerDeviceStyle: CoreMockupDeviceStyle(
      screenAspectWidth: width - inset * 2,
      screenAspectHeight: height - inset * 2,
    ),
  );
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, dynamic>;
  final geometry = doc['geometry'] as Map<String, dynamic>;
  final tableWidth = (geometry['width'] as num).toDouble();
  final tableHeight = (geometry['height'] as num).toDouble();
  final tableThickness = (geometry['thickness'] as num).toDouble();
  final tablePerspective = (geometry['perspective'] as num).toDouble();
  final vectors = (doc['vectors'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final tableStyle = _tableStyle(
    width: tableWidth,
    height: tableHeight,
    thickness: tableThickness,
    perspective: tablePerspective,
  );
  final tableLayout = _layout(
    width: tableWidth,
    innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle.merge(
      tableStyle.innerDeviceStyle,
    ),
    coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
    thickness: tableThickness,
    perspective: tablePerspective,
  );
  // The corners the table's edge cuts are derived for: the open body's, and
  // the cover's away from the hinge.
  CoreMockupFoldCorner tableCorner(String key) {
    final pair = (geometry[key] as List<dynamic>).cast<num>();

    return (x: pair.first.toDouble(), y: pair.last.toDouble());
  }

  final tableInnerCorner = tableCorner('innerCorner');
  final tableCoverCorner = tableCorner('coverCorner');
  final tableCornerStyle = tableStyle.merge(
    CoreMockupFoldableStyle(
      innerDeviceStyle: CoreMockupDeviceStyle(
        borderRadius: CoreBorderRadius.all(tableInnerCorner.x),
      ),
      coverDeviceStyle: CoreMockupDeviceStyle(
        borderRadius: CoreBorderRadius.only(
          topRight: tableCoverCorner.x,
          bottomRight: tableCoverCorner.x,
        ),
      ),
    ),
  );

  /// Each slab's outer edge: the strip the pose places and what fills it.
  Map<String, ({WebElementChrome strip, WebElementChrome fill})> edgesOf(
    ResolvedMockupFoldable resolved,
  ) => {
    'right': (strip: resolved.rightEdge, fill: resolved.rightEdgeFill),
    'left': (strip: resolved.leftEdge, fill: resolved.leftEdgeFill),
  };

  /// Each part's chrome, with the box its transform is applied to.
  Map<String, ({WebElementChrome chrome, double width, double height})> partsOf(
    ResolvedMockupFoldable resolved, {
    required double width,
    required double height,
    required double thickness,
  }) => {
    'innerRight': (chrome: resolved.rightHalf, width: width, height: height),
    'innerLeft': (chrome: resolved.leftHalf, width: width, height: height),
    'cover': (chrome: resolved.cover, width: width / 2, height: height),
    'edgeLeft': (chrome: resolved.leftEdge, width: thickness, height: height),
    'edgeRight': (
      chrome: resolved.rightEdge,
      width: thickness,
      height: height,
    ),
  };

  group('MockupFoldable resolver — the shared table', () {
    testComponents('the table is not empty and covers both ends', (
      tester,
    ) async {
      final angles = [for (final v in vectors) (v['angle'] as num).toDouble()];
      expect(
        angles,
        containsAll([
          CoreMockupFold.closed,
          CoreMockupFold.halfOpen,
          CoreMockupFold.flat,
        ]),
      );
    });

    for (final vector in vectors) {
      final angle = (vector['angle'] as num).toDouble();
      final table = vector['parts'] as Map<String, dynamic>;

      testComponents('at $angle° — the transform lists multiply out to where '
          'the table puts every part', (tester) async {
        final resolved = _resolve(
          _themedContext(tester),
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: tableStyle,
        );
        // The geometry under test is the table's: the stage is its box.
        expect(_rem(_style(resolved.root, 'width')), closeTo(tableWidth, 1e-9));
        expect(
          _rem(_style(resolved.root, 'height')),
          closeTo(tableHeight, 1e-9),
        );

        final failures = <String>[];
        final parts = partsOf(
          resolved,
          width: tableWidth,
          height: tableHeight,
          thickness: tableThickness,
        );
        for (final entry in parts.entries) {
          final part = entry.value;
          final expected = table[entry.key] as Map<String, dynamic>;
          // The box the transform is applied to is the part's own.
          expect(
            _rem(_style(part.chrome, 'width')),
            closeTo(part.width, 1e-9),
            reason: '${entry.key} width',
          );
          expect(
            _rem(_style(part.chrome, 'height')),
            closeTo(part.height, 1e-9),
            reason: '${entry.key} height',
          );
          expect(_style(part.chrome, 'transform-origin'), '0 0');

          final corners = _corners(
            _matrixOf(_style(part.chrome, 'transform')),
            part.width,
            part.height,
          );
          final tableCorners = (expected['corners'] as List<dynamic>)
              .cast<List<dynamic>>();
          for (var i = 0; i < corners.length; i++) {
            final x = (tableCorners[i][0] as num).toDouble();
            final y = (tableCorners[i][1] as num).toDouble();
            if ((corners[i].x - x).abs() > _kCornerTolerance ||
                (corners[i].y - y).abs() > _kCornerTolerance) {
              failures.add(
                '${entry.key} corner $i: (${corners[i].x}, ${corners[i].y}), '
                'table ($x, $y)',
              );
            }
          }
        }

        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testComponents('at $angle° — a part is displayed only while the table '
          'says it faces the viewer', (tester) async {
        final resolved = _resolve(
          _themedContext(tester),
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: tableStyle,
        );
        final flat = vector['isFlat'] as bool;
        bool visible(String name) =>
            (table[name] as Map<String, dynamic>)['visible'] as bool;

        // Flat, the open body is drawn as it is and no half is.
        expect(
          _has(resolved.rightHalf, 'hidden'),
          flat || !visible('innerRight'),
        );
        expect(
          _has(resolved.leftHalf, 'hidden'),
          flat || !visible('innerLeft'),
        );
        expect(_has(resolved.cover, 'hidden'), !visible('cover'));
        expect(_has(resolved.leftEdge, 'hidden'), !visible('edgeLeft'));
        expect(_has(resolved.rightEdge, 'hidden'), !visible('edgeRight'));
        // The open body itself: shown flat, hidden — not removed — bent.
        expect(_has(resolved.live, 'invisible'), !flat);
        // …and out of sight whatever a descendant says of its own
        // visibility.
        expect(_has(resolved.live, 'opacity-0'), !flat);
        expect(_has(resolved.live, 'hidden'), isFalse);
      });

      testComponents('at $angle° — which screen is lit, how dark the other '
          'is, and what the content is told', (tester) async {
        final resolved = _resolve(
          _themedContext(tester),
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: tableStyle,
        );
        final runtime = resolved.runtime;

        expect(runtime.activeScreen.name, vector['activeScreen']);
        expect(runtime.isFlat, vector['isFlat']);
        expect(
          _strength(resolved.innerScrim),
          closeTo((vector['innerScreenDim'] as num).toDouble(), _kAlphaStep),
        );
        expect(
          _strength(resolved.coverScrim),
          closeTo((vector['coverScreenDim'] as num).toDouble(), _kAlphaStep),
        );
        // The strength rides the colour, not the element: a layer that
        // faded as a whole would be a different statement on Flutter.
        for (final layer in [resolved.innerScrim, resolved.coverScrim]) {
          expect(
            layer.inlineStyles!.properties.containsKey('opacity'),
            isFalse,
          );
        }
        // What the content reads is the shared layout's answer for the
        // screen it is on.
        expect(runtime.foldLayout, tableLayout.foldLayoutAt(angle));
        if (vector['activeScreen'] == 'cover') {
          // The cover is a screen with no fold.
          expect(runtime.foldLayout.folds, isEmpty);
          expect(runtime.foldLayout.width, tableLayout.coverScreen.width);
        } else {
          expect(runtime.foldLayout.width, tableLayout.innerScreen.width);
          expect(
            runtime.foldLayout.folds.single.state.name,
            vector['foldState'],
          );
        }
      });
    }
  });

  group('MockupFoldable resolver — how the edges end', () {
    final variables = _radiusVariables();

    test('the table states a cut for an edge wherever it draws one, for '
        'corners that are circles and not the same on both faces', () {
      expect(tableInnerCorner.x, tableInnerCorner.y);
      expect(tableCoverCorner.x, tableCoverCorner.y);
      expect(tableCoverCorner, isNot(tableInnerCorner));
      // The stylesheet states both as the scale does: a reference to either
      // is read as the corner the table was derived for.
      expect(
        variables[_radiusVariable(tableInnerCorner.y)],
        tableInnerCorner.y,
      );
      expect(
        variables[_radiusVariable(tableCoverCorner.y)],
        tableCoverCorner.y,
      );

      var cuts = 0;
      for (final vector in vectors) {
        final stated = vector['edgeCuts'] as Map<String, dynamic>;
        final parts = vector['parts'] as Map<String, dynamic>;
        for (final (side, part) in [
          ('right', 'edgeRight'),
          ('left', 'edgeLeft'),
        ]) {
          final drawn = (parts[part] as Map<String, dynamic>)['visible'];
          expect(stated[side] != null, drawn, reason: '${vector['angle']}°');
          if (stated[side] != null) cuts++;
        }
      }
      // A table with no cut in it would pass the tests below by comparing
      // nothing.
      expect(cuts, greaterThan(10));
    });

    for (final vector in vectors) {
      final angle = (vector['angle'] as num).toDouble();
      final stated = vector['edgeCuts'] as Map<String, dynamic>;

      testComponents('at $angle° — each edge is a strip that clips a fill '
          'cut the way the table cuts it', (tester) async {
        final resolved = _resolve(
          _themedContext(tester),
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: tableCornerStyle,
        );

        for (final entry in edgesOf(resolved).entries) {
          final side = entry.key;
          final (:strip, :fill) = entry.value;
          final cut = stated[side] as Map<String, dynamic>?;

          // The strip is the box the pose places: as wide as the slab is
          // deep. It draws nothing itself and shows what of its fill lies
          // inside it.
          expect(_rem(_style(strip, 'width')), tableThickness, reason: side);
          expect(_has(strip, 'overflow-hidden'), isTrue, reason: side);
          expect(
            strip.inlineStyles!.properties.containsKey('background-color'),
            isFalse,
            reason: side,
          );
          expect(
            strip.className.split(' ').where((c) => c.startsWith('bg-')),
            isEmpty,
            reason: side,
          );
          // The fill is as tall as the strip, from its top, and carries the
          // edge colour.
          for (final className in ['absolute', 'top-0', 'h-full']) {
            expect(_has(fill, className), isTrue, reason: '$side $className');
          }
          expect(
            _style(fill, 'background-color'),
            CoreMockupFoldableStyle.defaultEdgeColor.toValue(),
            reason: side,
          );

          if (cut == null) {
            // Not drawn: nothing is displayed, and no cut is stated for it.
            expect(_has(strip, 'hidden'), isTrue, reason: side);
            expect(_radii(fill), isEmpty, reason: side);
            expect(
              _rem(_style(fill, 'width')),
              tableThickness,
              reason: side,
            );
            continue;
          }
          expect(_has(strip, 'hidden'), isFalse, reason: side);

          // Pinned to the side the device's outline is on, and to that one
          // only — the box grows away from it.
          final atEnd = cut['outlineAtEnd'] as bool;
          final (outline, away) = atEnd ? ('right', 'left') : ('left', 'right');
          expect(_has(fill, '$outline-0'), isTrue, reason: '$side pinned');
          expect(_has(fill, '$away-0'), isFalse, reason: '$side pinned');

          // Rounded on that side by the table's corners …
          final reaches = <double>[tableThickness];
          for (final end in ['top', 'bottom']) {
            final want = (cut[end] as List<dynamic>).cast<num>();
            final got = _corner(fill, end, outline, variables);
            expect(got, isNotNull, reason: '$side $end');
            expect(
              got!.x,
              closeTo(want.first.toDouble(), _kCutTolerance),
              reason: '$side $end across',
            );
            expect(
              got.y,
              closeTo(want.last.toDouble(), 1e-9),
              reason: '$side $end down',
            );
            reaches.add(want.first.toDouble());
          }
          // … square on the other …
          expect(
            _radii(fill).keys,
            unorderedEquals([
              'border-top-$outline-radius',
              'border-bottom-$outline-radius',
            ]),
            reason: side,
          );
          // … and as wide as the strip or its wider corner, whichever is
          // more: a corner wider than its box would be shrunk to fit it.
          expect(
            _px(_style(fill, 'width'), variables),
            closeTo(reaches.reduce(math.max), _kCutTolerance),
            reason: '$side width',
          );
        }
      });
    }

    testComponents('the cut is written in the variable its corner is drawn '
        'with, so what re-points that variable moves the cut with the '
        'corner', (tester) async {
      final context = _themedContext(tester);
      // Compact density draws a 16 corner as 14 — in the stylesheet alone,
      // with no rebuild — and leaves 24 where it is.
      final compact = _radiusVariables(
        under: '[$kDensityAttribute="${CoreDensity.compact.name}"]',
      );
      final innerKey = _radiusVariable(tableInnerCorner.y);
      final coverKey = _radiusVariable(tableCoverCorner.y);
      final innerMoved = compact[innerKey]!;
      expect(innerMoved, isNot(tableInnerCorner.y));
      expect(compact[coverKey], tableCoverCorner.y);
      // A style that draws no corner at all.
      final squared = {for (final key in variables.keys) key: 0.0};

      // 60°: both edges are cut by the open body's corners. 144°: the left
      // one by the cover's.
      for (final (angle, leftKey) in [(60.0, innerKey), (144.0, coverKey)]) {
        final resolved = _resolve(
          context,
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: tableCornerStyle,
        );
        final pose = tableLayout.poseAt(angle);
        final movedCuts = {
          'right': pose.rightEdgeCut(
            top: _round(innerMoved),
            bottom: _round(innerMoved),
          ),
          'left': pose.leftEdgeCut(
            innerTop: _round(innerMoved),
            innerBottom: _round(innerMoved),
            coverTop: tableCoverCorner,
            coverBottom: tableCoverCorner,
          ),
        };

        for (final entry in edgesOf(resolved).entries) {
          final side = entry.key;
          final fill = entry.value.fill;
          final key = side == 'right' ? innerKey : leftKey;
          final moved = movedCuts[side]!;
          final outline = moved.outlineAtEnd ? 'right' : 'left';
          final reason = '$angle° $side';

          // Every length but the strip's own is a reference: no number
          // stands in for a corner.
          final written = [_style(fill, 'width'), ..._radii(fill).values];
          expect(written, hasLength(3), reason: reason);
          for (final value in written) {
            expect(value, contains('var($key)'), reason: reason);
            expect(value, isNot(contains('px')), reason: '$reason: $value');
          }

          for (final (end, want) in [
            ('top', moved.top),
            ('bottom', moved.bottom),
          ]) {
            final atRest = _corner(fill, end, outline, variables)!;
            final shifted = _corner(fill, end, outline, compact)!;
            final ratio = compact[key]! / variables[key]!;
            // The cut moves by exactly as much as its corner …
            expect(shifted.y, compact[key], reason: '$reason $end');
            expect(
              shifted.x,
              closeTo(atRest.x * ratio, 1e-9),
              reason: '$reason $end',
            );
            // … which is where the shared rule cuts a body drawn with the
            // moved corner, to a part in four hundred. Not exactly: the
            // camera draws a shorter corner a little differently along its
            // length, and a stylesheet can only scale the one it was given.
            expect(
              shifted.x,
              closeTo(want.x, want.x * _kMovedCutShare),
              reason: '$reason $end',
            );
            expect(shifted.y, want.y, reason: '$reason $end');
            // With no corner there is no cut: the plain strip.
            expect(
              _corner(fill, end, outline, squared),
              (x: 0.0, y: 0.0),
              reason: '$reason $end',
            );
          }
          expect(
            _px(_style(fill, 'width'), squared),
            tableThickness,
            reason: reason,
          );
        }
      }
    });

    testComponents('a body with square corners leaves the strip plain', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final square = tableStyle.merge(
        const CoreMockupFoldableStyle(
          innerDeviceStyle: CoreMockupDeviceStyle(
            borderRadius: CoreBorderRadius.zero,
          ),
          coverDeviceStyle: CoreMockupDeviceStyle(
            borderRadius: CoreBorderRadius.zero,
          ),
        ),
      );

      for (final angle in [20.0, 60.0, 90.0, 144.0]) {
        final resolved = _resolve(
          context,
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: square,
        );
        for (final entry in edgesOf(resolved).entries) {
          final (:strip, :fill) = entry.value;
          final reason = '$angle° ${entry.key}';

          expect(_radii(fill), isEmpty, reason: reason);
          // The strip's own box, stated as it is — nothing to take the
          // larger of.
          expect(_style(fill, 'width'), _style(strip, 'width'), reason: reason);
          expect(_has(strip, 'overflow-hidden'), isTrue, reason: reason);
        }
      }
    });

    testComponents('each end is cut by its own corner: the open body\u2019s '
        'on that side, or the cover\u2019s away from the hinge', (
      tester,
    ) async {
      final context = _themedContext(tester);
      // Six corners, no two alike, one of them square.
      const inner = CoreBorderRadius.only(
        topLeft: 8,
        topRight: 12,
        bottomLeft: 20,
        bottomRight: 24,
      );
      const cover = CoreBorderRadius.only(bottomRight: 32);
      final style = tableStyle.merge(
        const CoreMockupFoldableStyle(
          innerDeviceStyle: CoreMockupDeviceStyle(borderRadius: inner),
          coverDeviceStyle: CoreMockupDeviceStyle(borderRadius: cover),
        ),
      );

      for (final angle in [60.0, 144.0]) {
        final resolved = _resolve(
          context,
          widgetWidth: tableWidth,
          foldAngle: angle,
          mockupFoldableStyle: style,
        );
        final pose = tableLayout.poseAt(angle);
        final cuts = {
          'right': pose.rightEdgeCut(
            top: _round(inner.topRight),
            bottom: _round(inner.bottomRight),
          ),
          'left': pose.leftEdgeCut(
            innerTop: _round(inner.topLeft),
            innerBottom: _round(inner.bottomLeft),
            coverTop: _round(cover.topRight),
            coverBottom: _round(cover.bottomRight),
          ),
        };

        for (final entry in edgesOf(resolved).entries) {
          final side = entry.key;
          final fill = entry.value.fill;
          final cut = cuts[side]!;
          final outline = cut.outlineAtEnd ? 'right' : 'left';
          final reaches = <double>[tableThickness];

          for (final (end, want) in [
            ('top', cut.top),
            ('bottom', cut.bottom),
          ]) {
            final reason = '$angle° $side $end';
            final got = _corner(fill, end, outline, variables);
            if (want.x == 0) {
              // A square corner cuts nothing off its end.
              expect(got, isNull, reason: reason);
              continue;
            }
            expect(got!.x, closeTo(want.x, _kCutTolerance), reason: reason);
            expect(got.y, want.y, reason: reason);
            // Stated in that corner's own variable.
            expect(
              _style(fill, 'border-$end-$outline-radius'),
              endsWith(' var(${_radiusVariable(want.y)})'),
              reason: reason,
            );
            reaches.add(want.x);
          }
          expect(
            _px(_style(fill, 'width'), variables),
            closeTo(reaches.reduce(math.max), _kCutTolerance),
            reason: '$angle° $side width',
          );
        }
        // The cover's square corner is the left edge's top once the cover
        // has turned away — one end cut, one plain.
        if (angle == 144.0) {
          expect(_radii(resolved.leftEdgeFill).keys, [
            'border-bottom-left-radius',
          ]);
        }
      }
    });

    testComponents('a corner off the radius scale is cut as the number it '
        'is', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: tableWidth,
        foldAngle: 60,
        mockupFoldableStyle: tableStyle.merge(
          const CoreMockupFoldableStyle(
            innerDeviceStyle: CoreMockupDeviceStyle(
              borderRadius: CoreBorderRadius.all(13),
            ),
          ),
        ),
      );
      final cut = tableLayout
          .poseAt(60)
          .rightEdgeCut(top: _round(13), bottom: _round(13));
      final got = _corner(resolved.rightEdgeFill, 'top', 'right', variables)!;

      // The body states that corner as a literal too; the two stay one
      // number.
      expect(
        _style(resolved.rightEdgeFill, 'border-top-right-radius'),
        matches(RegExp(r' 13(\.0)?px$')),
      );
      expect(got.x, closeTo(cut.top.x, _kCutTolerance));
      expect(got.y, 13);
    });
  });

  group('MockupFoldable resolver — the transform is written in rem', () {
    const angles = [0.0, 37.0, 90.0, 144.0, 171.0];

    testComponents('at another width the parts land where Core puts them', (
      tester,
    ) async {
      const width = 731.0;
      final context = _themedContext(tester);
      final layout = _layout(
        width: width,
        innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
        coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
        thickness: CoreMockupFoldableStyle.defaultThickness,
        perspective: CoreMockupFoldableStyle.defaultPerspective,
      );

      for (final angle in angles) {
        final resolved = _resolve(
          context,
          widgetWidth: width,
          foldAngle: angle,
        );
        final pose = layout.poseAt(angle);
        final core = {
          'innerRight': pose.innerRight,
          'innerLeft': pose.innerLeft,
          'cover': pose.cover,
          'edgeLeft': pose.edgeLeft,
          'edgeRight': pose.edgeRight,
        };
        final parts = partsOf(
          resolved,
          width: layout.width,
          height: layout.height,
          thickness: layout.thickness,
        );
        for (final entry in parts.entries) {
          final part = entry.value;
          final drawn = _corners(
            _matrixOf(_style(part.chrome, 'transform')),
            part.width,
            part.height,
          );
          final expected = _corners(
            core[entry.key]!.matrix,
            part.width,
            part.height,
          );
          for (var i = 0; i < drawn.length; i++) {
            expect(
              drawn[i].x,
              closeTo(expected[i].x, _kCornerTolerance),
              reason: '$angle° ${entry.key} corner $i x',
            );
            expect(
              drawn[i].y,
              closeTo(expected[i].y, _kCornerTolerance),
              reason: '$angle° ${entry.key} corner $i y',
            );
          }
        }
      }
    });

    testComponents('at a 20px root font the picture is the same one, a '
        'quarter larger — a matrix in px would not follow the bodies', (
      tester,
    ) async {
      const rootFont = 20.0;
      const scale = rootFont / _kRootFont;
      final context = _themedContext(tester);
      final layout = _layout(
        width: CoreMockupFoldableStyle.defaultWidth,
        innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
        coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
        thickness: CoreMockupFoldableStyle.defaultThickness,
        perspective: CoreMockupFoldableStyle.defaultPerspective,
      );

      for (final angle in angles) {
        final resolved = _resolve(
          context,
          widgetWidth: CoreMockupFoldableStyle.defaultWidth,
          foldAngle: angle,
        );
        // What Core draws for a device every length of which is `scale`
        // times as long — which is what a body sized in rem has become.
        final pose = layout.poseAt(angle, scale: scale);
        final drawn = _corners(
          _matrixOf(
            _style(resolved.leftHalf, 'transform'),
            rootFont: rootFont,
          ),
          layout.width * scale,
          layout.height * scale,
        );
        final expected = _corners(
          pose.innerLeft.matrix,
          layout.width * scale,
          layout.height * scale,
        );
        for (var i = 0; i < drawn.length; i++) {
          expect(
            drawn[i].x,
            closeTo(expected[i].x, _kCornerTolerance * scale),
            reason: '$angle° corner $i x',
          );
          expect(
            drawn[i].y,
            closeTo(expected[i].y, _kCornerTolerance * scale),
            reason: '$angle° corner $i y',
          );
        }
      }
    });
  });

  group('MockupFoldable resolver — the stage and what lies on the bodies', () {
    testComponents('the root is the box of the open body at every angle', (
      tester,
    ) async {
      const width = 400.0;
      final context = _themedContext(tester);
      final layout = _layout(
        width: width,
        innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
        coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
        thickness: CoreMockupFoldableStyle.defaultThickness,
        perspective: CoreMockupFoldableStyle.defaultPerspective,
      );

      for (var angle = 0.0; angle <= 180; angle += 12) {
        final resolved = _resolve(
          context,
          widgetWidth: width,
          foldAngle: angle,
        );

        expect(
          _rem(_style(resolved.root, 'width')),
          closeTo(layout.width, 1e-9),
          reason: '$angle°',
        );
        expect(
          _rem(_style(resolved.root, 'height')),
          closeTo(layout.height, 1e-9),
          reason: '$angle°',
        );
        expect(_has(resolved.root, 'relative'), isTrue);
        expect(resolved.runtime.width, layout.width);
        expect(resolved.runtime.coverWidth, layout.coverWidth);
      }
    });

    testComponents('an angle outside the range reads as the nearer end', (
      tester,
    ) async {
      final context = _themedContext(tester);
      ResolvedMockupFoldable at(double angle) => _resolve(
        context,
        widgetWidth: CoreMockupFoldableStyle.defaultWidth,
        foldAngle: angle,
      );

      expect(
        _style(at(-40).cover, 'transform'),
        _style(at(CoreMockupFold.closed).cover, 'transform'),
      );
      expect(
        _style(at(400).leftHalf, 'transform'),
        _style(at(CoreMockupFold.flat).leftHalf, 'transform'),
      );
      expect(at(400).runtime.isFlat, isTrue);
    });

    testComponents('each half is cut at the hinge, with room for what the '
        'body draws outside its box; the left one laps a pixel over it, '
        'across the body only', (tester) async {
      const width = 480.0;
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.halfOpen,
      );
      final height = _rem(_style(resolved.root, 'height'));

      // The right half: inset(top right bottom left), each measured in from
      // its own side — it starts on the hinge.
      final inset = RegExp(
        r'^inset\((.*)\)$',
      ).firstMatch(_style(resolved.rightHalfCut, 'clip-path'))!;
      final right = [for (final side in inset.group(1)!.split(' ')) _rem(side)];
      expect(right[3], closeTo(width / 2, 1e-9));
      for (final side in right.take(3)) {
        expect(side, lessThan(-100));
      }

      // The left half: an outline that ends on the hinge above and below
      // the body, and a pixel past it from the body's top to its bottom.
      final polygon = RegExp(
        r'^polygon\((.*)\)$',
      ).firstMatch(_style(resolved.leftHalfCut, 'clip-path'))!;
      final outline = [
        for (final corner in polygon.group(1)!.split(', '))
          (
            x: _rem(corner.split(' ').first),
            y: _rem(corner.split(' ').last),
          ),
      ];
      final reach = -outline.first.x;
      expect(reach, greaterThan(100));
      expect(
        [for (final corner in outline) (corner.x, corner.y)],
        [
          (-reach, -reach),
          (width / 2, -reach),
          (width / 2, 0.0),
          (width / 2 + 1, 0.0),
          (width / 2 + 1, height),
          (width / 2, height),
          (width / 2, height + reach),
          (-reach, height + reach),
        ],
      );
    });

    testComponents('the cut is a box inside the turned half, never the '
        'turned half\u2019s own', (tester) async {
      final context = _themedContext(tester);

      // At every angle, shown or not: the shape does not change with it.
      for (final angle in [0.0, 20.0, 60.0, 90.0, 144.0, 179.0, 180.0]) {
        final resolved = _resolve(
          context,
          widgetWidth: 480,
          foldAngle: angle,
        );
        for (final (turned, cut) in [
          (resolved.rightHalf, resolved.rightHalfCut),
          (resolved.leftHalf, resolved.leftHalfCut),
        ]) {
          // A browser applies a clip stated on an element it turns in 3D to
          // a picture of that element taken at one device pixel per px, and
          // on a dense screen the half comes out soft. Seen in Chrome; here
          // only where the clip is stated can be held.
          expect(
            turned.inlineStyles!.properties.keys,
            unorderedEquals([
              'width',
              'height',
              'transform-origin',
              'transform',
            ]),
            reason: '$angle°',
          );
          expect(_has(turned, 'overflow-hidden'), isFalse, reason: '$angle°');
          // The cut is the half's own box — what it holds stays where the
          // half would have laid it — and states the clip and nothing else:
          // a transform of its own would make it a turned element too.
          expect(cut.className, 'absolute inset-0', reason: '$angle°');
          expect(
            cut.inlineStyles!.properties.keys,
            ['clip-path'],
            reason: '$angle°',
          );
        }
      }
    });

    testComponents('the dark of a screen going off lies on that screen, and '
        'takes no pointer', (tester) async {
      const width = 480.0;
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: 45,
      );
      final layout = _layout(
        width: width,
        innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
        coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
        thickness: CoreMockupFoldableStyle.defaultThickness,
        perspective: CoreMockupFoldableStyle.defaultPerspective,
      );

      for (final (chrome, box) in [
        (resolved.innerScrim, layout.innerScreen),
        (resolved.coverScrim, layout.coverScreen),
      ]) {
        expect(_rem(_style(chrome, 'left')), closeTo(box.left, 1e-9));
        expect(_rem(_style(chrome, 'top')), closeTo(box.top, 1e-9));
        expect(_rem(_style(chrome, 'width')), closeTo(box.width, 1e-9));
        expect(_rem(_style(chrome, 'height')), closeTo(box.height, 1e-9));
        expect(_has(chrome, 'absolute'), isTrue);
        expect(_has(chrome, 'pointer-events-none'), isTrue);
      }
      expect(
        _style(resolved.innerScrim, 'border-radius'),
        layout.innerScreenBorderRadius.toValue(),
      );
      expect(
        _style(resolved.coverScrim, 'border-radius'),
        layout.coverScreenBorderRadius.toValue(),
      );
    });

    testComponents('a half turned from the viewer is shaded by the share '
        'Core gives, times the strength the style states', (tester) async {
      const width = 480.0;
      final context = _themedContext(tester);
      final layout = _layout(
        width: width,
        innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
        coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
        thickness: CoreMockupFoldableStyle.defaultThickness,
        perspective: CoreMockupFoldableStyle.defaultPerspective,
      );

      for (final angle in [0.0, 20.0, 90.0, 120.0, 144.0, 180.0]) {
        final pose = layout.poseAt(angle);
        for (final strength in [null, 0.8]) {
          final resolved = _resolve(
            context,
            widgetWidth: width,
            foldAngle: angle,
            mockupFoldableStyle: CoreMockupFoldableStyle(
              shadeOpacity: strength,
            ),
          );
          final applied =
              strength ?? CoreMockupFoldableStyle.defaultShadeOpacity;

          expect(
            _strength(resolved.rightShade),
            closeTo(pose.innerRight.shade * applied, _kAlphaStep),
            reason: '$angle° right',
          );
          expect(
            _strength(resolved.leftShade),
            closeTo(pose.innerLeft.shade * applied, _kAlphaStep),
            reason: '$angle° left',
          );
          expect(
            _strength(resolved.coverShade),
            closeTo(pose.cover.shade * applied, _kAlphaStep),
            reason: '$angle° cover',
          );
          for (final layer in [
            resolved.rightShade,
            resolved.leftShade,
            resolved.coverShade,
          ]) {
            expect(
              layer.inlineStyles!.properties.containsKey('opacity'),
              isFalse,
            );
          }
        }
      }
    });

    testComponents('the shade follows the corners of the body it lies on', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: 480,
        foldAngle: CoreMockupFold.halfOpen,
      );

      expect(
        _style(resolved.rightShade, 'border-radius'),
        resolved.innerDeviceStyle.borderRadius!.toValue(),
      );
      expect(
        _style(resolved.coverShade, 'border-radius'),
        resolved.coverDeviceStyle.borderRadius!.toValue(),
      );
    });
  });

  group('MockupFoldable resolver — the style arrives', () {
    testComponents('the theme sets how deep a slab is and the instance '
        'overrides it', (tester) async {
      const themed = CoreComponentTheme(
        mockupFoldable: CoreMockupFoldableTheme(
          style: CoreMockupFoldableStyle(thickness: 20),
        ),
      );
      final context = _contextUnder(tester, themed);
      final fromTheme = _resolve(
        context,
        widgetWidth: 480,
        foldAngle: 60,
      );
      final fromInstance = _resolve(
        context,
        widgetWidth: 480,
        foldAngle: 60,
        mockupFoldableStyle: const CoreMockupFoldableStyle(thickness: 28),
      );

      expect(_rem(_style(fromTheme.leftEdge, 'width')), 20);
      expect(_rem(_style(fromTheme.rightEdge, 'width')), 20);
      expect(
        _style(fromTheme.cover, 'transform'),
        contains('translate3d(15rem, 0, -1.25rem)'),
      );
      expect(_rem(_style(fromInstance.leftEdge, 'width')), 28);
      expect(
        _style(fromInstance.cover, 'transform'),
        contains('translate3d(15rem, 0, -1.75rem)'),
      );
    });

    testComponents('without either, the design default is used', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: 480,
        foldAngle: 60,
      );

      expect(
        _rem(_style(resolved.leftEdge, 'width')),
        CoreMockupFoldableStyle.defaultThickness,
      );
      expect(
        _cameraDistance(_style(resolved.cover, 'transform')),
        closeTo(480 * CoreMockupFoldableStyle.defaultPerspective, 1e-3),
      );
      expect(
        resolved.runtime.duration,
        CoreMockupFoldableStyle.defaultDuration,
      );
      expect(resolved.runtime.curve, CoreMockupFoldableStyle.defaultCurve);
    });

    testComponents('the camera stands as many widths away as the style says', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: 480,
        foldAngle: 60,
        mockupFoldableStyle: const CoreMockupFoldableStyle(perspective: 4),
      );

      for (final chrome in [
        resolved.rightHalf,
        resolved.leftHalf,
        resolved.cover,
        resolved.leftEdge,
        resolved.rightEdge,
      ]) {
        expect(
          _cameraDistance(_style(chrome, 'transform')),
          closeTo(480 * 4, 1e-3),
        );
      }
    });

    testComponents('an edge is filled with a token colour as a class and '
        'any other colour inline — never both', (tester) async {
      final context = _themedContext(tester);
      const literal = CoreColor(0xFF123456);
      final token = _resolve(
        context,
        widgetWidth: 480,
        foldAngle: 60,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          edgeColor: CoreColor.token(CoreColors.primary),
        ),
      );
      final raw = _resolve(
        context,
        widgetWidth: 480,
        foldAngle: 60,
        mockupFoldableStyle: const CoreMockupFoldableStyle(edgeColor: literal),
      );

      for (final chrome in [token.leftEdgeFill, token.rightEdgeFill]) {
        expect(_has(chrome, 'bg-primary'), isTrue, reason: chrome.className);
        expect(
          chrome.inlineStyles!.properties.containsKey('background-color'),
          isFalse,
        );
      }
      for (final chrome in [raw.leftEdgeFill, raw.rightEdgeFill]) {
        expect(_style(chrome, 'background-color'), literal.toValue());
        expect(
          chrome.className.split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
      }
      // The colour is the fill's alone: a strip that carried it too would
      // paint its whole box, corners and all.
      for (final chrome in [
        token.leftEdge,
        token.rightEdge,
        raw.leftEdge,
        raw.rightEdge,
      ]) {
        expect(
          chrome.className.split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
        expect(
          chrome.inlineStyles!.properties.containsKey('background-color'),
          isFalse,
        );
      }
    });

    testComponents('the dark of a screen and the shade are filled inline '
        'with the colour the style states, token or not — their alpha is of '
        'this angle, and no class stands for that', (tester) async {
      final context = _themedContext(tester);
      // At 45° the inner screen is half dark, the cover's fully, and both
      // halves are shaded.
      final token = _resolve(
        context,
        widgetWidth: 480,
        foldAngle: 45,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          screenOffColor: CoreColor.token(CoreColors.inverseSurface),
          shadeColor: CoreColor.token(CoreColors.scrim),
        ),
      );
      const literal = CoreColor(0xFF123456);
      final raw = _resolve(
        context,
        widgetWidth: 480,
        foldAngle: 45,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          screenOffColor: literal,
          shadeColor: literal,
        ),
      );

      // A token stays a reference the browser reads, so it follows the
      // theme; only the alpha is written out.
      expect(
        _style(token.innerScrim, 'background-color'),
        'rgb(var(--coui-inverse-surface) / 50%)',
      );
      expect(
        _style(token.coverScrim, 'background-color'),
        'rgb(var(--coui-inverse-surface))',
      );
      for (final shade in [token.rightShade, token.leftShade]) {
        expect(
          _style(shade, 'background-color'),
          matches(RegExp(r'^rgb\(var\(--coui-scrim\) / [0-9]+%\)$')),
        );
      }
      expect(_style(raw.innerScrim, 'background-color'), startsWith('rgba('));
      expect(
        _style(raw.innerScrim, 'background-color'),
        contains('18, 52, 86'),
      );
      expect(_strength(raw.innerScrim), closeTo(0.5, _kAlphaStep));
      expect(_style(raw.coverScrim, 'background-color'), literal.toValue());
      for (final chrome in [
        token.innerScrim,
        token.coverScrim,
        token.rightShade,
        token.leftShade,
        token.coverShade,
        raw.innerScrim,
        raw.rightShade,
      ]) {
        expect(
          chrome.className.split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
      }
    });

    testComponents('a nested device style reaches its body, and the values '
        'the two bodies must agree on stay pinned', (tester) async {
      const rail = CoreColor(0xFFAA5500);
      const themed = CoreComponentTheme(
        mockupFoldable: CoreMockupFoldableTheme(
          style: CoreMockupFoldableStyle(
            innerDeviceStyle: CoreMockupDeviceStyle(bezelWidth: 14),
          ),
        ),
      );
      final resolved = _resolve(
        _contextUnder(tester, themed),
        widgetWidth: 480,
        foldAngle: 60,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          coverDeviceStyle: CoreMockupDeviceStyle(railColor: rail),
        ),
      );
      final plain = _resolve(
        _themedContext(tester),
        widgetWidth: 480,
        foldAngle: 60,
      );

      // The instance's nested slot arrives…
      expect(resolved.coverDeviceStyle.railColor, rail);
      expect(plain.coverDeviceStyle.railColor, isNot(rail));
      // …and the theme's, on the other body, where it moves the screen box.
      expect(resolved.innerDeviceStyle.bezelWidth, 14);
      expect(
        _rem(_style(resolved.innerScrim, 'left')),
        greaterThan(_rem(_style(plain.innerScrim, 'left'))),
      );
      // The cover is still half the open body wide and as tall: the layout
      // states its proportions and corners back on the style.
      expect(resolved.coverDeviceStyle.borderRadius, isNotNull);
      expect(resolved.coverDeviceStyle.screenAspectWidth, isNotNull);
      expect(resolved.coverDeviceStyle.screenAspectHeight, isNotNull);
      expect(resolved.runtime.coverWidth, 240);
    });

    testComponents('how the fold moves is for the style to say', (
      tester,
    ) async {
      const duration = Duration(milliseconds: CoreDuration.ms250);
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: 480,
        foldAngle: 60,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          duration: duration,
          curve: CoreEasing.linear,
        ),
      );

      expect(resolved.runtime.duration, duration);
      expect(resolved.runtime.curve, CoreEasing.linear);
    });
  });

  group('MockupFoldable — the status island', () {
    const width = CoreMockupFoldableStyle.defaultWidth;
    const scale = CoreMockupFoldableStyle.defaultSystemScale;
    // The island's lengths at the defaults, as the screen draws them.
    const column = CoreMockupFoldableStyle.defaultIslandWidth * scale;
    const offset = CoreMockupFoldableStyle.defaultIslandOffset * scale;
    const cameraSize = CoreMockupFoldableStyle.defaultIslandCameraSize * scale;

    /// The shared layout of a device styled with [style] at the default
    /// width — what the resolver is given to write out.
    CoreMockupFoldableLayout layoutOf([CoreMockupFoldableStyle? style]) =>
        _layout(
          width: width,
          innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle
              .merge(style?.innerDeviceStyle),
          coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle
              .merge(style?.coverDeviceStyle),
          thickness: CoreMockupFoldableStyle.defaultThickness,
          perspective: CoreMockupFoldableStyle.defaultPerspective,
          style: style,
        );

    /// The box [item] is laid in, in logical px, read back from its styles.
    CoreMockupDeviceRect boxOf(ResolvedMockupDeviceStatusItem item) => (
      left: _rem(_style(item.root, 'left')),
      top: _rem(_style(item.root, 'top')),
      width: _rem(_style(item.root, 'width')),
      height: _rem(_style(item.root, 'height')),
    );

    void expectBox(
      ResolvedMockupDeviceStatusItem item,
      CoreMockupDeviceRect want, {
      required String reason,
    }) {
      final box = boxOf(item);
      expect(box.left, closeTo(want.left, 1e-9), reason: '$reason: left');
      expect(box.top, closeTo(want.top, 1e-9), reason: '$reason: top');
      expect(box.width, closeTo(want.width, 1e-9), reason: '$reason: width');
      expect(box.height, closeTo(want.height, 1e-9), reason: '$reason: height');
    }

    /// The colour classes [chrome] wears for [prefix] (`bg` / `text`), the
    /// role's own `text-{role}` class left out.
    Iterable<String> colourClasses(WebElementChrome chrome, String prefix) =>
        chrome.className
            .split(' ')
            .where((c) => c.startsWith('$prefix-'))
            .where((c) => !c.startsWith('text-title-'))
            .where((c) => !c.startsWith('text-label-'));

    testComponents('the cover’s camera is a round hole at the top-right of '
        'its screen: centred in the island’s column, the island’s offset '
        'down', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.closed,
      );
      final screen = layoutOf().coverScreen;
      final camera = resolved.coverScreen.islandItems.first;
      final box = boxOf(camera);

      expect(box.width, closeTo(cameraSize, 1e-9));
      expect(box.height, closeTo(cameraSize, 1e-9));
      expect(box.top, closeTo(offset, 1e-9));
      // Centred across the column, which ends on the screen's right edge.
      expect(
        box.left + box.width / 2,
        closeTo(screen.width - column / 2, 1e-9),
      );
      // The top-right corner of the screen, in so many words.
      expect(box.left, greaterThan(screen.width * 3 / 4));
      expect(box.top + box.height, lessThan(screen.height / 4));
      // A circle: half the box, derived.
      expect(
        _rem(_style(camera.root, 'border-radius')),
        closeTo(cameraSize / 2, 1e-9),
      );
      expect(_has(camera.root, 'absolute'), isTrue);
      // It draws nothing but its fill.
      expect(camera.content.text, isNull);
      expect(camera.content.path, isNull);
      expect(camera.parts, isEmpty);
    });

    testComponents('under the camera come the clock and the status '
        'indicator, each where the shared layout stands it', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.closed,
      );
      final want = layoutOf().islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: true,
        showStatus: true,
      )!;
      final items = resolved.coverScreen.islandItems;

      expect(items, hasLength(3));
      expectBox(items.first, want.camera!, reason: 'camera');
      expectBox(items[1], want.clock!, reason: 'clock');
      expectBox(items[2], want.indicator!, reason: 'indicator');
      // Top to bottom, none over another.
      expect(
        boxOf(items[1]).top,
        greaterThan(boxOf(items.first).top + cameraSize),
      );
      expect(
        boxOf(items[2]).top,
        greaterThanOrEqualTo(boxOf(items[1]).top + boxOf(items[1]).height),
      );
    });

    testComponents('the inner screen’s island has no camera: the clock '
        'starts at the island’s offset, at the screen’s right edge', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.flat,
      );
      final layout = layoutOf();
      final want = layout.islandOf(
        CoreMockupFoldScreen.inner,
        showCamera: true,
        showStatus: true,
      )!;
      final items = resolved.innerScreen.islandItems;

      expect(want.camera, isNull);
      expect(items, hasLength(2));
      expectBox(items.first, want.clock!, reason: 'clock');
      expectBox(items[1], want.indicator!, reason: 'indicator');
      expect(boxOf(items.first).top, closeTo(offset, 1e-9));
      // The clock's line is the column itself, so its words are centred in
      // the column whatever their width.
      expect(boxOf(items.first).width, closeTo(column, 1e-9));
      expect(
        boxOf(items.first).left,
        closeTo(layout.innerScreen.width - column, 1e-9),
      );
    });

    testComponents('the clock is the sample time in the role a status bar '
        'sets it in, at the screen’s system scale, on one line', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.flat,
      );

      for (final screen in [resolved.innerScreen, resolved.coverScreen]) {
        final clock = screen.islandItems.firstWhere(
          (item) => item.content.text != null,
        );

        expect(clock.content.text, '9:41');
        expect(clock.content.text, CoreMockupFoldableStyle.sampleTime);
        expect(
          clock.root.className.split(' '),
          containsAll([
            'absolute',
            'flex',
            'items-center',
            'justify-center',
            'whitespace-nowrap',
            'text-title-small',
            'text-on-surface',
          ]),
        );
        // Never cut: words wider than the column run over it.
        expect(clock.root.className, isNot(contains('overflow')));
        expect(clock.root.className, isNot(contains('truncate')));
        // The role's own size, shrunk — read from the role's variable, so a
        // project's type scale drives it as it drives the class.
        expect(
          _style(clock.root, 'font-size'),
          'calc(var(--coui-text-title-small-size) * $scale)',
        );
        expect(_style(clock.root, '--coui-text-scale'), '$scale');
        // A token colour rides its class.
        expect(clock.root.inlineStyles!.properties.containsKey('color'), false);
      }
    });

    testComponents('the status indicator is two drawings in one box — the '
        'ring with its glyph, and the dots — each one colour', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.flat,
      );
      final indicator = resolved.innerScreen.islandItems.last;

      expect(indicator.content.path, isNull);
      expect(indicator.parts, hasLength(2));
      final [ring, dots] = indicator.parts;
      const ringGlyph = CoreMockupFoldableStyle.islandRingGlyph;
      const dotsGlyph = CoreMockupFoldableStyle.islandDotsGlyph;

      expect(ring.content.path, ringGlyph.path);
      expect(ring.content.fillRule, 'evenodd');
      expect(
        ring.content.viewBox,
        '0 0 ${ringGlyph.width} ${ringGlyph.height}',
      );
      expect(dots.content.path, dotsGlyph.path);
      expect(dots.content.fillRule, 'nonzero');
      expect(
        dots.content.viewBox,
        '0 0 ${dotsGlyph.width} ${dotsGlyph.height}',
      );
      for (final drawing in [ring, dots]) {
        // Stretched over the indicator's box, so one lies on the other.
        expect(
          drawing.root.className.split(' '),
          containsAll(['absolute', 'inset-0', 'h-full', 'w-full']),
        );
        expect(drawing.root.inlineStyles, isNull);
      }
      // The glyphs are filled with `currentColor`: the colour is a text
      // colour, the ring's the icon's and the dots' their quieter one.
      expect(colourClasses(ring.root, 'text'), ['text-on-surface']);
      expect(colourClasses(dots.root, 'text'), ['text-on-surface/30']);
      // The box is square, the size the drawing is stated in at this scale.
      final box = boxOf(indicator);
      expect(box.width, closeTo(ringGlyph.width * scale, 1e-9));
      expect(box.height, closeTo(ringGlyph.height * scale, 1e-9));
    });

    testComponents('the content is laid out clear of the island: the room '
        'it is given stops short of the screen’s right edge by the column', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.halfOpen,
      );

      for (final screen in [resolved.innerScreen, resolved.coverScreen]) {
        expect(
          _rem(_style(screen.root, 'padding-right')),
          closeTo(column, 1e-9),
        );
        // The padding is inside the room, and the room is the screen's
        // whole safe area: a height the content states still has a box.
        expect(_style(screen.root, 'box-sizing'), 'border-box');
        expect(_has(screen.root, 'h-full'), isTrue);
        // Pinned, like the device's own safe area: no spacing variable a
        // density could re-point.
        expect(_style(screen.root, 'padding-right'), isNot(contains('var(')));
        expect(_style(screen.root, 'padding-right'), endsWith('rem'));
      }
    });

    testComponents('the island lies over the whole screen, out of the way '
        'of a pointer', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.flat,
      );

      for (final screen in [resolved.innerScreen, resolved.coverScreen]) {
        final island = screen.island!;

        expect(
          island.className.split(' ').toSet(),
          {'absolute', 'inset-0', 'pointer-events-none'},
        );
        // Every part is placed in the screen's own frame: the layer adds no
        // offset of its own.
        expect(island.inlineStyles, isNull);
      }
    });

    testComponents('without its camera the cover’s clock moves up into its '
        'place; the inner screen is as it was', (tester) async {
      final context = _themedContext(tester);
      final drawn = _resolve(context, widgetWidth: width, foldAngle: 0);
      final left = _resolve(
        context,
        widgetWidth: width,
        foldAngle: 0,
        showCamera: false,
      );
      final items = left.coverScreen.islandItems;

      expect(items, hasLength(2));
      expect(items.first.content.text, '9:41');
      expect(boxOf(items.first).top, closeTo(offset, 1e-9));
      expect(
        boxOf(items.first).top,
        lessThan(boxOf(drawn.coverScreen.islandItems[1]).top),
      );
      // The column is still kept clear: the status stands in it.
      expect(
        _rem(_style(left.coverScreen.root, 'padding-right')),
        closeTo(column, 1e-9),
      );
      expect(left.innerScreen.islandItems, hasLength(2));
      for (var i = 0; i < 2; i++) {
        expect(
          left.innerScreen.islandItems[i].root.inlineStyles!.properties,
          drawn.innerScreen.islandItems[i].root.inlineStyles!.properties,
        );
      }
    });

    testComponents('without the status the cover keeps its camera alone, '
        'and the inner screen has no island and gives its content the whole '
        'width', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.halfOpen,
        showStatus: false,
      );
      final cover = resolved.coverScreen;
      final inner = resolved.innerScreen;

      expect(cover.islandItems, hasLength(1));
      expect(boxOf(cover.islandItems.single).top, closeTo(offset, 1e-9));
      expect(cover.islandItems.single.content.text, isNull);
      expect(cover.island, isNotNull);
      expect(
        _rem(_style(cover.root, 'padding-right')),
        closeTo(column, 1e-9),
      );
      expect(inner.island, isNull);
      expect(inner.islandItems, isEmpty);
      // The same room, with nothing taken from it.
      expect(_has(inner.root, 'h-full'), isTrue);
      expect(inner.root.inlineStyles, isNull);
    });

    testComponents('with neither a camera nor the status no screen has an '
        'island', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: CoreMockupFold.closed,
        showCamera: false,
        showStatus: false,
      );

      for (final screen in [resolved.innerScreen, resolved.coverScreen]) {
        expect(screen.island, isNull);
        expect(screen.islandItems, isEmpty);
        expect(screen.root.inlineStyles, isNull);
      }
    });

    testComponents('the island is the screen’s, not the angle’s: it is '
        'written the same wherever the device is folded to', (tester) async {
      final context = _themedContext(tester);
      Map<String, Object?> written(ResolvedMockupFoldable resolved) => {
        for (final (name, screen) in [
          ('inner', resolved.innerScreen),
          ('cover', resolved.coverScreen),
        ]) ...{
          '$name.root': screen.root.className,
          '$name.root.styles': screen.root.inlineStyles?.properties,
          '$name.island': screen.island?.className,
          for (final (i, item) in screen.islandItems.indexed) ...{
            '$name.$i': item.root.className,
            '$name.$i.styles': item.root.inlineStyles?.properties,
            '$name.$i.text': item.content.text,
            '$name.$i.parts': [
              for (final part in item.parts) part.root.className,
            ],
          },
        },
      };
      final flat = written(
        _resolve(context, widgetWidth: width, foldAngle: 180),
      );

      for (final angle in [0.0, 20.0, 60.0, 90.0, 144.0]) {
        expect(
          written(_resolve(context, widgetWidth: width, foldAngle: angle)),
          flat,
          reason: 'at $angle°',
        );
      }
    });

    testComponents('a token colour is a class and any other colour inline '
        '— never both: the camera, the ring and the dots', (tester) async {
      final context = _themedContext(tester);
      const literal = CoreColor(0xFF123456);
      final plain = _resolve(context, widgetWidth: width, foldAngle: 0);
      final token = _resolve(
        context,
        widgetWidth: width,
        foldAngle: 0,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          islandCameraColor: CoreColor.token(CoreColors.primary),
          islandIconColor: CoreColor.token(CoreColors.primary),
          islandDotColor: CoreColor.token(CoreColors.error),
        ),
      );
      final raw = _resolve(
        context,
        widgetWidth: width,
        foldAngle: 0,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          islandCameraColor: literal,
          islandIconColor: literal,
          islandDotColor: literal,
        ),
      );
      ({WebElementChrome camera, WebElementChrome ring, WebElementChrome dots})
      partsOf(ResolvedMockupFoldable resolved) {
        final items = resolved.coverScreen.islandItems;

        return (
          camera: items.first.root,
          ring: items.last.parts.first.root,
          dots: items.last.parts.last.root,
        );
      }

      // The defaults: the camera's black is a literal — hardware does not
      // follow the theme — and the indicator's two colours are tokens.
      final byDefault = partsOf(plain);
      expect(
        _style(byDefault.camera, 'background-color'),
        CoreMockupFoldableStyle.defaultIslandCameraColor.toValue(),
      );
      expect(colourClasses(byDefault.camera, 'bg'), isEmpty);
      expect(colourClasses(byDefault.ring, 'text'), ['text-on-surface']);
      expect(byDefault.ring.inlineStyles, isNull);
      expect(colourClasses(byDefault.dots, 'text'), ['text-on-surface/30']);
      expect(byDefault.dots.inlineStyles, isNull);

      final tokens = partsOf(token);
      expect(colourClasses(tokens.camera, 'bg'), ['bg-primary']);
      expect(
        tokens.camera.inlineStyles!.properties.containsKey('background-color'),
        isFalse,
      );
      expect(colourClasses(tokens.ring, 'text'), ['text-primary']);
      expect(tokens.ring.inlineStyles, isNull);
      expect(colourClasses(tokens.dots, 'text'), ['text-error']);
      expect(tokens.dots.inlineStyles, isNull);

      final raws = partsOf(raw);
      expect(_style(raws.camera, 'background-color'), literal.toValue());
      expect(colourClasses(raws.camera, 'bg'), isEmpty);
      for (final drawing in [raws.ring, raws.dots]) {
        expect(_style(drawing, 'color'), literal.toValue());
        expect(colourClasses(drawing, 'text'), isEmpty);
      }
      // The inner screen's indicator is drawn from the same two colours.
      final inner = raw.innerScreen.islandItems.last.parts;
      expect(_style(inner.first.root, 'color'), literal.toValue());
      expect(_style(inner.last.root, 'color'), literal.toValue());
    });

    testComponents('the clock’s text style reaches it: another role is '
        'another class and another variable, a colour alone keeps the role', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const literal = CoreColor(0xFF123456);
      WebElementChrome clockOf(CoreTextStyle style) => _resolve(
        context,
        widgetWidth: width,
        foldAngle: 180,
        mockupFoldableStyle: CoreMockupFoldableStyle(islandTextStyle: style),
      ).innerScreen.islandItems.first.root;

      final role = clockOf(
        const CoreTextStyle.token(
          CoreTextStyles.labelSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
      );
      expect(_has(role, 'text-label-small'), isTrue);
      expect(_has(role, 'text-title-small'), isFalse);
      expect(_has(role, 'text-primary'), isTrue);
      expect(_has(role, 'text-on-surface'), isFalse);
      expect(
        _style(role, 'font-size'),
        'calc(var(--coui-text-label-small-size) * $scale)',
      );

      final colourOnly = clockOf(const CoreTextStyle(color: literal));
      expect(_has(colourOnly, 'text-title-small'), isTrue);
      expect(_has(colourOnly, 'text-on-surface'), isFalse);
      expect(_style(colourOnly, 'color'), literal.toValue());
      expect(
        _style(colourOnly, 'font-size'),
        'calc(var(--coui-text-title-small-size) * $scale)',
      );

      // A size the style states itself is shrunk as the role's would be.
      final sized = clockOf(const CoreTextStyle(fontSize: 20));
      expect(_rem(_style(sized, 'font-size')), closeTo(20 * scale, 1e-9));
    });

    testComponents('the island’s three lengths reach both screens, in iOS '
        'points at the screen’s scale', (tester) async {
      const style = CoreMockupFoldableStyle(
        islandWidth: 120,
        islandOffset: 40,
        islandCameraSize: 48,
      );
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: 0,
        mockupFoldableStyle: style,
      );
      final layout = layoutOf(style);

      for (final (screen, which) in [
        (resolved.innerScreen, CoreMockupFoldScreen.inner),
        (resolved.coverScreen, CoreMockupFoldScreen.cover),
      ]) {
        final want = layout.islandOf(
          which,
          showCamera: true,
          showStatus: true,
        )!;
        final wanted = [?want.camera, ?want.clock, ?want.indicator];

        expect(
          _rem(_style(screen.root, 'padding-right')),
          closeTo(120 * scale, 1e-9),
        );
        expect(screen.islandItems, hasLength(wanted.length));
        for (final (i, box) in wanted.indexed) {
          expectBox(screen.islandItems[i], box, reason: '${which.name} $i');
        }
      }
      final [camera, clock, _] = resolved.coverScreen.islandItems;
      expect(boxOf(camera).top, closeTo(40 * scale, 1e-9));
      expect(boxOf(camera).width, closeTo(48 * scale, 1e-9));
      // The gap under the camera is the drawing's own, not a length the
      // style states.
      expect(
        boxOf(clock).top,
        closeTo(
          (40 + 48 + CoreMockupFoldableStyle.islandCameraGap) * scale,
          1e-9,
        ),
      );
    });

    testComponents('the theme’s island reaches the screens, and the '
        'instance’s wins over it', (tester) async {
      const literal = CoreColor(0xFF123456);
      const themed = CoreComponentTheme(
        mockupFoldable: CoreMockupFoldableTheme(
          style: CoreMockupFoldableStyle(
            islandWidth: 120,
            islandIconColor: literal,
          ),
        ),
      );
      final context = _contextUnder(tester, themed);
      final fromTheme = _resolve(context, widgetWidth: width, foldAngle: 180);
      final fromInstance = _resolve(
        context,
        widgetWidth: width,
        foldAngle: 180,
        mockupFoldableStyle: const CoreMockupFoldableStyle(islandWidth: 80),
      );

      expect(
        _rem(_style(fromTheme.innerScreen.root, 'padding-right')),
        closeTo(120 * scale, 1e-9),
      );
      expect(
        _style(
          fromTheme.innerScreen.islandItems.last.parts.first.root,
          'color',
        ),
        literal.toValue(),
      );
      expect(
        _rem(_style(fromInstance.innerScreen.root, 'padding-right')),
        closeTo(80 * scale, 1e-9),
      );
      // What the instance does not state is still the theme's.
      expect(
        _style(
          fromInstance.innerScreen.islandItems.last.parts.first.root,
          'color',
        ),
        literal.toValue(),
      );
    });

    testComponents('each screen’s island is drawn at the scale its own '
        'device draws system lengths at', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        widgetWidth: width,
        foldAngle: 180,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          innerDeviceStyle: CoreMockupDeviceStyle(
            landscapeSystemBarReferenceScale: 1,
          ),
        ),
      );
      final inner = resolved.innerScreen;
      final cover = resolved.coverScreen;

      // The open body at one px to the point: the column is its 96 points.
      expect(
        _rem(_style(inner.root, 'padding-right')),
        closeTo(CoreMockupFoldableStyle.defaultIslandWidth, 1e-9),
      );
      expect(
        _style(inner.islandItems.first.root, 'font-size'),
        'calc(var(--coui-text-title-small-size) * 1.0)',
      );
      // The cover's device was left alone.
      expect(_rem(_style(cover.root, 'padding-right')), closeTo(column, 1e-9));
      expect(
        _style(cover.islandItems[1].root, 'font-size'),
        'calc(var(--coui-text-title-small-size) * $scale)',
      );
    });

    testComponents('what the islands are drawn from is one value the '
        'component can compare: the same from frame to frame, another when '
        'the island changes', (tester) async {
      final context = _themedContext(tester);
      final at60 = _resolve(context, widgetWidth: width, foldAngle: 60);
      final at144 = _resolve(context, widgetWidth: width, foldAngle: 144);
      final wider = _resolve(
        context,
        widgetWidth: width,
        foldAngle: 144,
        mockupFoldableStyle: const CoreMockupFoldableStyle(islandWidth: 120),
      );
      final tinted = _resolve(
        context,
        widgetWidth: width,
        foldAngle: 144,
        mockupFoldableStyle: const CoreMockupFoldableStyle(
          islandTextStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
        ),
      );

      // Chrome does not compare — an inline style is a new object each
      // time — so this is what tells the component its bodies still stand.
      expect(
        at60.innerScreen.root == at144.innerScreen.root,
        isFalse,
        reason: 'the reason the value exists',
      );
      expect(at60.runtime.islandStyle, at144.runtime.islandStyle);
      expect(at144.runtime.islandStyle, isNot(wider.runtime.islandStyle));
      expect(at144.runtime.islandStyle, isNot(tinted.runtime.islandStyle));
      // Settled: every island field is stated, the defaults included.
      final settled = at60.runtime.islandStyle;
      expect(settled.islandWidth, CoreMockupFoldableStyle.defaultIslandWidth);
      expect(settled.islandOffset, CoreMockupFoldableStyle.defaultIslandOffset);
      expect(
        settled.islandCameraSize,
        CoreMockupFoldableStyle.defaultIslandCameraSize,
      );
      expect(
        settled.islandCameraColor,
        CoreMockupFoldableStyle.defaultIslandCameraColor,
      );
      expect(
        settled.islandTextStyle,
        CoreMockupFoldableStyle.defaultIslandTextStyle,
      );
      expect(
        settled.islandIconColor,
        CoreMockupFoldableStyle.defaultIslandIconColor,
      );
      expect(
        settled.islandDotColor,
        CoreMockupFoldableStyle.defaultIslandDotColor,
      );
      // A colour laid over the default role keeps the role.
      expect(
        tinted.runtime.islandStyle.islandTextStyle!.token,
        CoreTextStyles.titleSmall,
      );
    });
  });
}
