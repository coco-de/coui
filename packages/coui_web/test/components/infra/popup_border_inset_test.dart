// A panel's border lies over its inset, not outside it.
//
// A CSS `border` sits outside the padding, so a panel that states a padding
// of 6 and a border of 1 stood 7 from its edge to its content — a 240 menu
// 206 tall with its rows 226 wide where Flutter draws 204 and 228. Flutter
// paints a `DecoratedBox` border over the padding, and the composed panels
// the design states (a menu's rows 6 in from the edge, the selection toolbar
// 40 tall) are measured that way, so the border comes out of the padding:
// the line stays drawn and the box is the size the padding says.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

Future<void> _withContext(
  ComponentTester tester,
  void Function(BuildContext context) body,
) async {
  late BuildContext captured;
  tester.pumpComponent(
    Theme.defaults(
      child: Builder(
        builder: (context) {
          captured = context;
          return const div([]);
        },
      ),
    ),
  );
  body(captured);
}

String _inside(double side, double border) =>
    'calc(${spaceCss(side)} - ${strokeWidthCss(border)})';

/// The same, measured against the border a Popup actually keeps: what is left
/// of its width once a material that draws its own edge has folded it away.
String _insideKept(double side, double border) =>
    'calc(${spaceCss(side)} - '
    '${surfaceClipKeptBorder(strokeWidthCss(border))})';

void main() {
  group('CoreEdgeInsets.toDeclarationsWithinBorder', () {
    test('a symmetric inset is the one-line shorthand of four calcs', () {
      final declarations =
          const CoreEdgeInsets.all(
            CoreSpace.space6,
          ).toDeclarationsWithinBorder(
            'padding',
            strokeWidthCss(CoreStrokeWidth.stroke1),
          );

      final side = _inside(CoreSpace.space6, CoreStrokeWidth.stroke1);
      expect(declarations, {'padding': '$side $side $side $side'});
    });

    test('a directional inset keeps its logical longhands', () {
      final declarations =
          const CoreEdgeInsets.directional(
            start: CoreSpace.space12,
            end: CoreSpace.space4,
            top: CoreSpace.space4,
            bottom: CoreSpace.space4,
          ).toDeclarationsWithinBorder(
            'padding',
            strokeWidthCss(CoreStrokeWidth.stroke1),
          );

      expect(declarations, {
        'padding-block-start': _inside(CoreSpace.space4, 1),
        'padding-block-end': _inside(CoreSpace.space4, 1),
        'padding-inline-start': _inside(CoreSpace.space12, 1),
        'padding-inline-end': _inside(CoreSpace.space4, 1),
      });
    });

    test('the border is the length it is given, so a variable reaches it', () {
      final declarations = const CoreEdgeInsets.all(
        CoreSpace.space8,
      ).toDeclarationsWithinBorder('padding', 'var(--coui-stroke-width-4)');

      expect(
        declarations['padding'],
        contains('calc(var(--coui-space-8) - var(--coui-stroke-width-4))'),
      );
    });
  });

  group('Popup', () {
    testComponents('a drawn border comes out of the padding', (tester) async {
      await _withContext(tester, (context) {
        final root = resolvePopup(
          context,
          direction: CoreAxis.vertical,
          popupStyle: CoreMenuStyle.defaultPopupStyle,
        ).root;
        final inline = root.inlineStyles!.properties;

        final side = _insideKept(CoreSpace.space6, CoreStrokeWidth.stroke1);
        expect(inline['padding'], '$side $side $side $side');
        // The line itself is unchanged.
        expect(inline['border-width'], strokeWidthCss(CoreStrokeWidth.stroke1));
      });
    });

    testComponents('a panel with no border keeps its padding whole', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final inline = resolvePopup(
          context,
          direction: CoreAxis.vertical,
          popupStyle: const CorePopupStyle(borderWidth: 0),
        ).root.inlineStyles!.properties;

        expect(inline['padding'], CorePopupStyle.defaultPadding.toValue());
      });
    });

    testComponents('a thicker border comes out by its own width', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final inline = resolvePopup(
          context,
          direction: CoreAxis.vertical,
          popupStyle: const CorePopupStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space8),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ).root.inlineStyles!.properties;

        final side = _insideKept(CoreSpace.space8, CoreStrokeWidth.stroke2);
        expect(inline['padding'], '$side $side $side $side');
      });
    });
  });

  group('Menubar', () {
    Map<String, String> bar(
      BuildContext context, {
      required bool border,
    }) => resolveMenubar(
      context,
      variant: CoreMenubarVariant.defaultVariant,
      border: border,
    ).root.inlineStyles!.properties;

    testComponents('a bordered bar takes the border out of its padding', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final inline = bar(context, border: true);
        const padding = CoreMenubarStyle.defaultBarPadding;

        expect(
          inline['padding'],
          padding.toDeclarationsWithinBorder(
            'padding',
            strokeWidthCss(CoreMenubarStyle.defaultBarBorderWidth),
          )['padding'],
        );
        expect(inline['padding'], contains('calc('));
      });
    });

    testComponents('a bar with no border keeps its padding whole', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final inline = bar(context, border: false);

        expect(
          inline['padding'],
          CoreMenubarStyle.defaultBarPadding.toValue(),
        );
      });
    });
  });
}
