// A dashed (or dotted) Frame border is drawn by an SVG overlay, but the box
// is the solid border's box: the Flutter twin keeps `Border.all(width)` in
// layout with its style switched off and strokes the dashes over it, so the
// frame is `2 × width` larger on each axis than a borderless one. Without the
// reservation the Web frame was 4px shorter than Flutter's at a 2px stroke.
//
// The width is reserved as *padding*, not as a transparent CSS border: the
// root clips its content at its padding box, and an overlay pulled out over a
// CSS border is clipped away with it — the dashes disappeared. With the space
// in the padding the padding box is the border box and the overlay's
// `inset: 0` covers exactly the box the dashes are stroked in.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

DomComponent _byId(String id) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere((c) => c.id == id);

DomComponent _svg() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere((c) => c.tag == 'svg');

Map<String, String> _inline(DomComponent c) => c.styles?.properties ?? const {};

const _kWidth = 'var(--coui-stroke-width-2)';

Frame _frame({
  required CoreFrameBorderStyle style,
  double? width = CoreStrokeWidth.stroke2,
}) => Frame(
  id: 'frame',
  padding: const CoreEdgeInsets.all(CoreSpace.space24),
  borderColor: const CoreColor(0xFF808080),
  borderWidth: width,
  borderStyle: style,
  child: const Text('label'),
);

void main() {
  group('a dashed Frame reserves its border width', () {
    testComponents('as padding on every side', (tester) async {
      pumpWithTheme(tester, _frame(style: .dashed));

      expect(
        _inline(_byId('frame'))['padding'],
        'calc(var(--coui-space-24) + $_kWidth) '
        'calc(var(--coui-space-24) + $_kWidth) '
        'calc(var(--coui-space-24) + $_kWidth) '
        'calc(var(--coui-space-24) + $_kWidth)',
      );
    });

    testComponents('and takes no CSS border (the clip would eat the dashes)', (
      tester,
    ) async {
      pumpWithTheme(tester, _frame(style: .dashed));

      final root = _byId('frame');

      expect(_inline(root).containsKey('border-width'), isFalse);
      expect((root.classes ?? '').split(' '), isNot(contains('border')));
    });

    testComponents('and leaves the overlay covering the whole box', (
      tester,
    ) async {
      pumpWithTheme(tester, _frame(style: .dashed));

      final overlay = _inline(_svg());

      expect(overlay.containsKey('inset'), isFalse);
      expect(overlay['width'], '100%');
      expect(overlay['height'], '100%');
    });

    testComponents('a dotted border reserves it too', (tester) async {
      pumpWithTheme(tester, _frame(style: .dotted));

      expect(_inline(_byId('frame'))['padding'], contains(_kWidth));
    });

    testComponents('with no padding the width alone is the padding', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Frame(
          id: 'frame',
          borderColor: CoreColor(0xFF808080),
          borderWidth: CoreStrokeWidth.stroke2,
          borderStyle: .dashed,
          child: Text('label'),
        ),
      );

      expect(_inline(_byId('frame'))['padding'], _kWidth);
    });

    testComponents('and states no width when the caller states none', (
      tester,
    ) async {
      pumpWithTheme(tester, _frame(style: .dashed, width: null));

      expect(
        _inline(_byId('frame'))['padding'],
        'var(--coui-space-24) var(--coui-space-24) '
        'var(--coui-space-24) var(--coui-space-24)',
      );
    });
  });

  group('a solid Frame is unchanged', () {
    testComponents('it keeps its CSS border, its own padding and no overlay', (
      tester,
    ) async {
      pumpWithTheme(tester, _frame(style: .solid));

      final root = _byId('frame');

      expect((root.classes ?? '').split(' '), contains('border'));
      expect(_inline(root)['border-width'], _kWidth);
      expect(_inline(root)['border-color'], isNot('transparent'));
      expect(
        _inline(root)['padding'],
        'var(--coui-space-24) var(--coui-space-24) '
        'var(--coui-space-24) var(--coui-space-24)',
      );
      expect(
        find
            .byType(DomComponent)
            .evaluate()
            .where(
              (e) => (e.component as DomComponent).tag == 'svg',
            ),
        isEmpty,
      );
    });
  });
}
