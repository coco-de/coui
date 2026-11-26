// Where the Web chat bubble puts its tail, and what its tail corner is —
// written from the CSS the resolver emits.
//
// The tail sits on one edge (`tailEdge`, bottom by default) on the side the
// bubble is aligned to. A drawn pointer squares that corner, anchors to that
// edge and is clipped to the same outline the Flutter painter draws, reflected
// for a top tail; a bubble with no pointer can shape that one corner with
// `tailCornerRadius`. The corners are read as `topLeft topRight bottomRight
// bottomLeft`, the order `border-radius` takes them.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

ResolvedChatBubble _resolve(
  ComponentTester tester, {
  CoreChatAlignment alignment = .start,
  bool tail = false,
  CoreChatBubbleStyle? style,
}) => resolveChatBubble(
  _themedContext(tester),
  variant: .defaultVariant,
  alignment: alignment,
  tail: tail,
  chatBubbleStyle: style,
);

/// `topLeft topRight bottomRight bottomLeft`, as `border-radius` emits them.
String _corners(ResolvedChatBubble resolved) =>
    _inline(resolved.root)['border-radius']!;

/// The points of the tail's `clip-path: path('…')`, as `x y` pairs.
List<(double, double)> _points(ResolvedChatBubble resolved) {
  final d = RegExp(
    r"path\('([^']*)'\)",
  ).firstMatch(_inline(resolved.tail!)['clip-path']!)!.group(1)!;
  final numbers = RegExp(
    r'-?\d+(?:\.\d+)?',
  ).allMatches(d).map((m) => double.parse(m.group(0)!)).toList();
  return [
    for (var i = 0; i + 1 < numbers.length; i += 2)
      (numbers[i], numbers[i + 1]),
  ];
}

const String _k14 = 'var(--coui-radius-14)';
const String _k6 = 'var(--coui-radius-6)';

const CoreChatBubbleStyle _kTopTail = CoreChatBubbleStyle(tailEdge: .top);

void main() {
  final square = radiusCss(0);

  group('ChatBubble tail on the top edge', () {
    testComponents('start: the top-left corner is square, three stay 14', (
      tester,
    ) async {
      expect(
        _corners(_resolve(tester, tail: true, style: _kTopTail)),
        '$square $_k14 $_k14 $_k14',
      );
    });

    testComponents('end: the top-right corner is square, three stay 14', (
      tester,
    ) async {
      expect(
        _corners(
          _resolve(tester, tail: true, alignment: .end, style: _kTopTail),
        ),
        '$_k14 $square $_k14 $_k14',
      );
    });

    testComponents('the pointer anchors to the top edge, not the bottom', (
      tester,
    ) async {
      final tail = _inline(
        _resolve(tester, tail: true, style: _kTopTail).tail!,
      );

      expect(tail['top'], '0');
      expect(tail.containsKey('bottom'), isFalse);
    });

    testComponents('the default edge keeps the pointer on the bottom', (
      tester,
    ) async {
      final tail = _inline(_resolve(tester, tail: true).tail!);

      expect(tail['bottom'], '0');
      expect(tail.containsKey('top'), isFalse);
    });

    testComponents('the top outline is the bottom one reflected', (
      tester,
    ) async {
      // Same x, y measured from the other edge — for both pointing sides.
      const h = CoreChatBubbleStyle.defaultTailHeight;
      for (final alignment in CoreChatAlignment.values) {
        final bottom = _points(
          _resolve(tester, tail: true, alignment: alignment),
        );
        final top = _points(
          _resolve(tester, tail: true, alignment: alignment, style: _kTopTail),
        );

        expect(top.length, bottom.length, reason: alignment.name);
        for (var i = 0; i < top.length; i++) {
          expect(top[i].$1, bottom[i].$1, reason: '${alignment.name} x[$i]');
          expect(
            top[i].$2,
            closeTo(h - bottom[i].$2, 0.01),
            reason: '${alignment.name} y[$i]',
          );
        }
      }
    });
  });

  group('ChatBubble tail corner without a pointer', () {
    testComponents('each edge and side names exactly one corner', (
      tester,
    ) async {
      String corners(CoreChatBubbleTailEdge edge, CoreChatAlignment side) =>
          _corners(
            _resolve(
              tester,
              alignment: side,
              style: CoreChatBubbleStyle(
                tailEdge: edge,
                tailCornerRadius: CoreRadius.radius6,
              ),
            ),
          );

      expect(corners(.bottom, .start), '$_k14 $_k14 $_k14 $_k6');
      expect(corners(.bottom, .end), '$_k14 $_k14 $_k6 $_k14');
      expect(corners(.top, .start), '$_k6 $_k14 $_k14 $_k14');
      expect(corners(.top, .end), '$_k14 $_k6 $_k14 $_k14');
    });

    testComponents('unstated, the corner follows a restated borderRadius', (
      tester,
    ) async {
      expect(
        _corners(
          _resolve(
            tester,
            style: const CoreChatBubbleStyle(
              borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
            ),
          ),
        ),
        List.filled(4, 'var(--coui-radius-20)').join(' '),
      );
    });

    testComponents('a drawn pointer still squares the corner', (tester) async {
      expect(
        _corners(
          _resolve(
            tester,
            tail: true,
            style: const CoreChatBubbleStyle(
              tailCornerRadius: CoreRadius.radius6,
            ),
          ),
        ),
        '$_k14 $_k14 $_k14 $square',
      );
    });

    testComponents('the stated corner goes out as its radius variable', (
      tester,
    ) async {
      // A variable is what a density or a surface style re-points; a literal
      // would hold this one corner still while they moved the other three.
      expect(
        _corners(
          _resolve(
            tester,
            style: const CoreChatBubbleStyle(
              tailEdge: .top,
              tailCornerRadius: CoreRadius.radius6,
            ),
          ),
        ).split(' ').first,
        'var(--coui-radius-6)',
      );
    });
  });
}
