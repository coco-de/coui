import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/util/core_to_css.dart'
    show kStateLayerHoverMarker, kStateLayerHoverVar;
import 'package:test/test.dart';

void main() {
  group('hover state layer rule', () {
    // The layer is a background-image over the box's own background-color,
    // so the face (a raised chosen fill, an edited primary-container fill, a
    // transparent unchosen segment) keeps its colour and the layer is added
    // over it. One global marker-class selector, no per-instance rule.
    test('is one global rule that lays the published colour on :hover', () {
      final css = ThemeConfig.defaults().cssVariables;

      expect(
        css,
        contains(
          '.$kStateLayerHoverMarker:hover{'
          'background-image:linear-gradient(var($kStateLayerHoverVar),'
          'var($kStateLayerHoverVar));}',
        ),
      );
      // Never a second background-color: that would replace the face.
      final rule = RegExp(
        r'\.' + kStateLayerHoverMarker + r':hover\{[^}]*\}',
      ).firstMatch(css)!.group(0)!;
      expect(rule, isNot(contains('background-color')));
    });
  });
}
