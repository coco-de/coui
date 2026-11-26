// What the Web clip contributes, and what it must not.
//
// The shape, the interpolation and the tempo are Core's and are held by
// Core's tests; the spelling is held by `util/liquid_morph_clip_path_test`.
// What is left here is the component's own contract — that it renders its
// target unchanged, and that the server ships an open panel rather than a
// half-drawn one.
//
// `testServer` (not `testComponents`) because only the real SSR binding
// hands back markup, and "no clip in the markup" is a claim about markup.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const _kPanelId = 'coui-test-panel';

const _kAnchor = CoreMorphBlob(
  centerX: 60,
  centerY: 190,
  halfWidth: 48,
  halfHeight: 18,
  radius: 8,
);
const _kPanel = CoreMorphBlob(
  centerX: 110,
  centerY: 70,
  halfWidth: 110,
  halfHeight: 70,
  radius: 16,
);

Component _clip({
  CoreMorphBlob anchor = _kAnchor,
  CoreMorphBlob panel = _kPanel,
}) => CoUIWeb(
  theme: .coui,
  child: LiquidMorphClip(
    elementId: _kPanelId,
    anchor: anchor,
    panel: panel,
    child: div([text('panel')], id: _kPanelId),
  ),
);

void main() {
  group('it names its target instead of wrapping it', () {
    testServer('the subtree reaches the document unchanged', (tester) async {
      // The Flutter twin wraps its child because clipping there is a render
      // node. Here it is a style property on an element that already
      // exists — usually the positioned panel itself — so an element of its
      // own would put a static box between the panel and whatever positions
      // it, changing the layout of every overlay to add an effect that
      // changes none of it.
      tester.pumpComponent(_clip());
      final response = await tester.request('/');
      final panel = response.document?.querySelector('#$_kPanelId');

      expect(panel, isNotNull);
      expect(panel!.text, contains('panel'));
      // The panel's parent is whatever was already there — not a wrapper
      // this component minted.
      expect(panel.parent?.id, isNot(_kPanelId));
      expect(panel.parent?.attributes['style'], isNot(contains('clip-path')));
    });
  });

  group('the server ships an open panel, not a half-drawn one', () {
    testServer('no clip is written into the markup', (tester) async {
      // A morph is a transition between two states and the server only
      // ever renders the second one. Markup carrying a mid-flight
      // `clip-path` would ship a partly-carved panel as the first thing a
      // user sees — and it would be carved against rectangles nobody had
      // measured, because there is nothing to measure here.
      tester.pumpComponent(_clip());
      final response = await tester.request('/');

      expect(response.body, isNot(contains('clip-path')));
      expect(response.body, isNot(contains('path(')));
    });

    testServer('and an unmeasured body still renders the panel', (
      tester,
    ) async {
      // Two zero-sized bodies do **not** trace nothing: the smooth union
      // pulls by `k / 4` even where both fields are a single point, so a
      // caller that has not measured its trigger yet would have its panel
      // carved into a dot. "No effect yet" and "the panel disappeared" have
      // to be different states on this side too.
      const unmeasured = CoreMorphBlob(
        centerX: 0,
        centerY: 0,
        halfWidth: 0,
        halfHeight: 0,
      );
      tester.pumpComponent(_clip(anchor: unmeasured, panel: unmeasured));
      final response = await tester.request('/');

      expect(response.document?.querySelector('#$_kPanelId'), isNotNull);
    });
  });
}
