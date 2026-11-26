// The Web's handles on adaptive quality that a server and a component tester
// can see: the attribute `CoUIWeb` writes on the document, the scope that
// publishes the tier to a subtree, and what an app that states nothing — or
// stops stating something — gets.
//
// The rules that attribute switches are `adaptive_quality_css_test.dart`'s and
// the sampler behind it is `adaptive_quality_sampler_test.dart`'s; this file
// pins only that the attribute lands where those look for it. The measuring
// itself is browser-only, so on the server and in these tests no governor
// runs: a tier here is one the app stated.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../helpers/html_attributes.dart';

/// The attribute the tier is written to — spelled out rather than read from
/// `kQualityAttribute`, so the test is a second source for it.
const String _kAttribute = 'data-coui-quality';

/// The quality tier the app declares on `<html>` — what jaspr puts on the
/// document — or `null` when it declares none.
String? _declared(ComponentTester tester) =>
    declaredHtmlAttributes(tester)[_kAttribute];

/// A `CoUIWeb` stating a forced tier, with a button that rebuilds it with no
/// statement and back.
class _ForceToggle extends StatefulComponent {
  const _ForceToggle();

  @override
  State<_ForceToggle> createState() => _ForceToggleState();
}

class _ForceToggleState extends State<_ForceToggle> {
  CoreAdaptiveQuality? _stated = const CoreAdaptiveQuality(
    forced: CoreQualityTier.solid,
  );

  @override
  Component build(BuildContext context) => CoUIWeb(
    theme: .coui,
    adaptiveQuality: _stated,
    child: button(
      const [],
      onClick: () => setState(
        () => _stated = _stated == null
            ? const CoreAdaptiveQuality(forced: CoreQualityTier.solid)
            : null,
      ),
    ),
  );
}

/// A `CoUIWeb` forcing one tier around [child], with a button that forces the
/// other.
class _TierSwitch extends StatefulComponent {
  const _TierSwitch({required this.child});

  final Component child;

  @override
  State<_TierSwitch> createState() => _TierSwitchState();
}

class _TierSwitchState extends State<_TierSwitch> {
  CoreQualityTier _tier = CoreQualityTier.noRefraction;

  @override
  Component build(BuildContext context) => CoUIWeb(
    theme: .coui,
    adaptiveQuality: CoreAdaptiveQuality(forced: _tier),
    child: Component.fragment([
      component.child,
      button(
        const [],
        onClick: () => setState(() => _tier = CoreQualityTier.solid),
      ),
    ]),
  );
}

/// Reads the scope the way an app would, and hands what it saw to [onBuild].
class _Probe extends StatelessComponent {
  const _Probe(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);

    return const div([]);
  }
}

void main() {
  group('CoUIWeb writes the tier on <html>', () {
    testServer('a forced tier is on the server-rendered document', (
      tester,
    ) async {
      // So the first paint is already at that tier, before any script runs.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          adaptiveQuality: const CoreAdaptiveQuality(
            forced: CoreQualityTier.solid,
          ),
          child: const div([]),
        ),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes[_kAttribute], 'solid');
    });

    testServer('an initial tier is where the server starts the page', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          adaptiveQuality: const CoreAdaptiveQuality(
            initialQuality: CoreQualityTier.noRefraction,
          ),
          child: const div([]),
        ),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes[_kAttribute], 'noRefraction');
    });

    testServer('an app that measures starts at the top, and says so', (
      tester,
    ) async {
      // The server measures nothing; naming the top is what lets a tier the
      // governor later gave up be lifted by the same attribute.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          adaptiveQuality: const CoreAdaptiveQuality(),
          child: const div([]),
        ),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes[_kAttribute], 'full');
    });

    testServer('no statement writes nothing: the style is drawn as stated', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: const div([])));
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes.containsKey(_kAttribute), isFalse);
    });

    testServer("no statement leaves a host page's tier on the document", (
      tester,
    ) async {
      // A host that sets the tier itself — its own `Document.html`, as a
      // page outside any CoUIWeb island would — keeps it through an island
      // that states none.
      tester.pumpComponent(
        Component.fragment([
          const Document.html(attributes: {_kAttribute: 'solid'}),
          CoUIWeb(theme: .coui, child: const div([])),
        ]),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes[_kAttribute], 'solid');
    });

    testServer('and one request does not leak into the next', (tester) async {
      // The tier is an ambient value and a document attribute, never a
      // module-level variable: the server handles requests concurrently.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          adaptiveQuality: const CoreAdaptiveQuality(
            forced: CoreQualityTier.solid,
          ),
          child: const div([]),
        ),
      );
      await tester.request('/');

      tester.pumpComponent(CoUIWeb(theme: .coui, child: const div([])));
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes.containsKey(_kAttribute), isFalse);
    });
  });

  group('CoUIWeb lifts a tier it wrote', () {
    testComponents('rebuilt with no statement, the document names the top', (
      tester,
    ) async {
      tester.pumpComponent(const _ForceToggle());
      expect(_declared(tester), 'solid');

      await tester.click(find.tag('button'));
      // On the client jaspr keeps every attribute a `Document.html` ever
      // declared on `<html>`, so leaving it out would keep `solid` — and the
      // page would stay opaque after the app stopped asking, where Flutter's
      // `CoUIApp` draws the style in full again. Naming the top lifts it.
      expect(_declared(tester), 'full');

      await tester.click(find.tag('button'));
      expect(_declared(tester), 'solid');
    });
  });

  group('AdaptiveQualityScope', () {
    testComponents('publishes the tier the app stated', (tester) async {
      final seen = <CoreQualityTier>[];
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          adaptiveQuality: const CoreAdaptiveQuality(
            forced: CoreQualityTier.noRefraction,
          ),
          child: _Probe(
            (context) => seen.add(AdaptiveQualityScope.of(context)),
          ),
        ),
      );

      expect(seen, isNotEmpty);
      expect(seen.last, CoreQualityTier.noRefraction);
    });

    testComponents('publishes the top where nothing is stated', (tester) async {
      final seen = <CoreQualityTier>[];
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _Probe(
            (context) => seen.add(AdaptiveQualityScope.of(context)),
          ),
        ),
      );

      expect(seen.last, CoreQualityTier.full);
    });

    testComponents('and the top where there is no scope at all', (
      tester,
    ) async {
      final seen = <CoreQualityTier>[];
      tester.pumpComponent(
        _Probe((context) => seen.add(AdaptiveQualityScope.of(context))),
      );

      expect(seen.last, CoreQualityTier.defaultTier);
    });

    testComponents('a hold needs no guard where nothing measures', (
      tester,
    ) async {
      // The server and the component tester run no governor, and an app that
      // wraps its heavy work in a hold must not have to know that.
      final holds = <CoreQualityHold>[];
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          adaptiveQuality: const CoreAdaptiveQuality(),
          child: _Probe(
            (context) =>
                holds.add(AdaptiveQualityScope.holdMeasurement(context)),
          ),
        ),
      );

      expect(holds, isNotEmpty);
      expect(holds.last.released, isTrue);
      holds.last.release();
    });

    testComponents('a change of tier reaches those who read it', (
      tester,
    ) async {
      final seen = <CoreQualityTier>[];
      tester.pumpComponent(
        _TierSwitch(
          child: _Probe(
            (context) => seen.add(AdaptiveQualityScope.of(context)),
          ),
        ),
      );
      expect(seen.last, CoreQualityTier.noRefraction);

      await tester.click(find.tag('button'));
      expect(seen.last, CoreQualityTier.solid);
      expect(_declared(tester), 'solid');
    });

    test('and a scope that publishes the same tier notifies nobody', () {
      const scope = AdaptiveQualityScope(
        tier: CoreQualityTier.solid,
        opensHold: null,
        child: div([]),
      );

      expect(scope.updateShouldNotify(scope), isFalse);
      expect(
        const AdaptiveQualityScope(
          tier: CoreQualityTier.full,
          opensHold: null,
          child: div([]),
        ).updateShouldNotify(scope),
        isTrue,
      );
    });
  });
}
