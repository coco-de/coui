// What the Window snap bar and its tiles draw when nothing is stated: the
// banner takes the panel corner and states the `lg` cast; a tile keeps corners
// of its own (4 on the preset's outer edge, 2 where two tiles abut) instead of
// borrowing the preview's and the banner's.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/window/window_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _context(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedWindowSnapTile _tile(
  ComponentTester tester, {
  required bool topLeftTight,
  required bool topRightTight,
  required bool bottomLeftTight,
  required bool bottomRightTight,
}) => resolveWindowSnapTile(
  _context(tester),
  hovering: false,
  leftCss: '0px',
  topCss: '0px',
  widthCss: '10px',
  heightCss: '10px',
  topLeftTight: topLeftTight,
  topRightTight: topRightTight,
  bottomLeftTight: bottomLeftTight,
  bottomRightTight: bottomRightTight,
);

void main() {
  group('Window snap bar default chrome', () {
    testComponents('the banner corner is the panel corner, 12', (tester) async {
      final inline = resolveWindow(
        _context(tester),
      ).snapBarContainer.inlineStyles!.properties;

      expect(inline['border-radius'], const CoreBorderRadius.all(12).toValue());
    });

    testComponents('the banner casts the lg step and its rim', (tester) async {
      final inline = resolveWindow(
        _context(tester),
      ).snapBarContainer.inlineStyles!.properties;

      // The step's own variable — an alpha tweak over the base colour would
      // have been a different, literal stack.
      expect(inline['box-shadow'], 'var(--shadow-lg), $kSurfaceRimVar');
    });

    testComponents('the banner is the bright surface with a subtle outline', (
      tester,
    ) async {
      final classes = resolveWindow(
        _context(tester),
      ).snapBarContainer.className;

      expect(classes, contains('bg-surface-bright'));
      expect(classes, contains('border-outline-subtle'));
    });
  });

  group('Window snap tile corners', () {
    testComponents('a tile alone on the preset is 4 on every corner', (
      tester,
    ) async {
      final inline = _tile(
        tester,
        topLeftTight: false,
        topRightTight: false,
        bottomLeftTight: false,
        bottomRightTight: false,
      ).root.inlineStyles!.properties;

      expect(inline['border-radius'], const CoreBorderRadius.all(4).toValue());
    });

    testComponents('a corner that abuts a sibling tile is 2', (tester) async {
      final inline = _tile(
        tester,
        topLeftTight: false,
        topRightTight: true,
        bottomLeftTight: false,
        bottomRightTight: true,
      ).root.inlineStyles!.properties;

      expect(
        inline['border-radius'],
        const CoreBorderRadius.only(
          topLeft: 4,
          topRight: 2,
          bottomLeft: 4,
          bottomRight: 2,
        ).toValue(),
      );
    });

    testComponents('a tile outlines itself in the variant outline', (
      tester,
    ) async {
      final classes = _tile(
        tester,
        topLeftTight: false,
        topRightTight: false,
        bottomLeftTight: false,
        bottomRightTight: false,
      ).root.className;

      expect(classes, contains('border-outline-variant'));
    });
  });
}
